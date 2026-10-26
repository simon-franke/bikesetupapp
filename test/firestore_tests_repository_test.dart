@TestOn('browser')
library;

import 'dart:async';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/tests/controllers/tests_controller.dart';
import 'package:bikesetupapp/features/tests/models/setup_test.dart';
import 'package:bikesetupapp/features/tests/repositories/tests_repository.dart';
import 'package:bikesetupapp/features/tests/repositories/firestore_tests_repository.dart';
import 'support/fake_repositories.dart';

/// Holds one accepted command until another session has committed a change.
class PausedUpdate implements TestsRepository {
  PausedUpdate(this.delegate);
  final TestsRepository delegate;
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Stream<List<SetupTest>> watch(String bike, String setup) =>
      delegate.watch(bike, setup);
  @override
  Future<void> create(String bike, String setup, SetupTest test) =>
      delegate.create(bike, setup, test);
  @override
  Future<void> update(String bike, String setup, String id,
      {required TestStage expectedStage,
      required SetupTest Function(SetupTest) change}) async {
    entered.complete();
    await release.future;
    await delegate.update(bike, setup, id,
        expectedStage: expectedStage, change: change);
  }

  @override
  Future<void> finish(String bike, String setup, String id,
          {bool apply = false, String? newSetupId, String? newSetupName}) =>
      delegate.finish(bike, setup, id,
          apply: apply, newSetupId: newSetupId, newSetupName: newSetupName);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebaseCoreWeb.registerWith(webPluginRegistrar);
  FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
  setUpAll(() async {
    // This suite only talks to the local demo emulator, never the app project.
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'demo-key',
            appId: '1:123:web:tests',
            messagingSenderId: '123',
            projectId: 'demo-bike-tests'));
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8086);
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: false);
  });

  String parentPath(String uid) =>
      'UserBikeSetup/$uid/Bikes/bike/SetupList/setup';
  SetupTest draft(String id) => SetupTest(id: id, name: 'Test', before: {
        'Fork': {'Rebound': '6 clicks', 'Compression': '4 clicks'}
      }, values: {
        'Fork': {'Rebound': '6 clicks', 'Compression': '4 clicks'}
      });

  Future<FirestoreTestsRepository> seed() async {
    final uid = DateTime.now().microsecondsSinceEpoch.toString();
    final db = FirebaseFirestore.instance;
    await db.doc(parentPath(uid)).set({'setup_name': 'Default'});
    await db
        .doc('UserBikeSetup/$uid/Bikes/bike/setup/Fork')
        .set(draft('test').before['Fork']!);
    final repo = FirestoreTestsRepository(uid);
    await repo.create('bike', 'setup', draft('test'));
    return repo;
  }

  Future<List<SetupTest>> serverTests(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('${parentPath(uid)}/Tests')
        .get(const GetOptions(source: Source.server));
    return snapshot.docs.map((doc) => SetupTest.fromMap(doc.data())).toList();
  }

  TestsController controller(TestsRepository repo) {
    final result = TestsController(repo, FakeSetupsRepository());
    addTearDown(result.dispose);
    return result;
  }

  test('a delayed edit preserves another session\'s different field edit',
      () async {
    final repo = await seed();
    final paused = PausedUpdate(repo);
    final a = controller(paused), b = controller(repo);
    final pending =
        a.updateField('bike', 'setup', 'test', 'Fork', 'Rebound', '8 clicks');
    await paused.entered.future;
    try {
      expect(
          (await b.updateField(
                  'bike', 'setup', 'test', 'Fork', 'Compression', '2 clicks'))
              .isSuccess,
          isTrue);
    } finally {
      paused.release.complete();
    }
    expect((await pending).isSuccess, isTrue);
    final stored = (await serverTests(repo.uid)).single;
    expect(stored.values['Fork'],
        {'Rebound': '8 clicks', 'Compression': '2 clicks'});
  });

  test('simultaneous transactions preserve both field edits', () async {
    final repo = await seed();
    final a = controller(repo), b = controller(repo);
    final results = await Future.wait([
      a.updateField('bike', 'setup', 'test', 'Fork', 'Rebound', '8 clicks'),
      b.updateField('bike', 'setup', 'test', 'Fork', 'Compression', '2 clicks'),
    ]);
    expect(results.every((result) => result.isSuccess), isTrue);
    expect((await serverTests(repo.uid)).single.values['Fork'],
        {'Rebound': '8 clicks', 'Compression': '2 clicks'});
  });

  test('a delayed edit cannot resurrect a discarded draft', () async {
    final repo = await seed();
    final paused = PausedUpdate(repo);
    final a = controller(paused), b = controller(repo);
    final pending =
        a.updateField('bike', 'setup', 'test', 'Fork', 'Rebound', '8 clicks');
    await paused.entered.future;
    try {
      expect((await b.finish('bike', 'setup', 'test')).isSuccess, isTrue);
      expect(await serverTests(repo.uid), isEmpty);
    } finally {
      paused.release.complete();
    }
    expect((await pending).isSuccess, isFalse);
    expect(await serverTests(repo.uid), isEmpty);
    final parent = await FirebaseFirestore.instance
        .doc(parentPath(repo.uid))
        .get(const GetOptions(source: Source.server));
    expect(parent.data()!.containsKey('activeTestId'), isFalse);
  });

  test('a delayed draft edit cannot roll back another session\'s stage',
      () async {
    final repo = await seed();
    final b = controller(repo);
    await b.updateField(
        'bike', 'setup', 'test', 'Fork', 'Compression', '2 clicks');
    final paused = PausedUpdate(repo);
    final a = controller(paused);
    final pending =
        a.updateField('bike', 'setup', 'test', 'Fork', 'Rebound', '8 clicks');
    await paused.entered.future;
    try {
      expect((await b.startTest('bike', 'setup', 'test', 'Ride')).isSuccess,
          isTrue);
    } finally {
      paused.release.complete();
    }
    expect((await pending).isSuccess, isFalse);
    final stored = (await serverTests(repo.uid)).single;
    expect(stored.stage, TestStage.ride);
    expect(stored.values['Fork']!['Rebound'], '6 clicks');
  });

  test(
      'creation cannot replace an existing test or create a second active test',
      () async {
    final repo = await seed();
    for (final id in ['test', 'another']) {
      await expectLater(
          repo.create('bike', 'setup', draft(id)), throwsA(isA<AppFailure>()));
    }
    expect(await serverTests(repo.uid), hasLength(1));
  });

  test('finish checks the stored stage and applies the latest test values',
      () async {
    final repo = await seed();
    final a = controller(repo), b = controller(repo);
    await a.updateField('bike', 'setup', 'test', 'Fork', 'Rebound', '8 clicks');
    await a.startTest('bike', 'setup', 'test', 'Ride');
    expect((await a.finish('bike', 'setup', 'test', apply: true)).isSuccess,
        isFalse);
    await b.logRide(
        'bike', 'setup', 'test', const RideFeedback(feeling: 'Better'));
    expect((await a.finish('bike', 'setup', 'test', apply: true)).isSuccess,
        isTrue);
    final stored = (await serverTests(repo.uid)).single;
    expect(stored.stage, TestStage.finished);
    expect(stored.rides.single.feeling, 'Better');
    final baseline = await FirebaseFirestore.instance
        .doc('UserBikeSetup/${repo.uid}/Bikes/bike/setup/Fork')
        .get(const GetOptions(source: Source.server));
    expect(baseline.data()!['Rebound'], '8 clicks');
    expect((await b.resumeTest('bike', 'setup', 'test')).isSuccess, isFalse);
  });
  test('baseline conflicts return a typed failure without partial writes',
      () async {
    final repo = await seed();
    final edits = controller(repo);
    await edits.updateField(
        'bike', 'setup', 'test', 'Fork', 'Rebound', '8 clicks');
    await edits.updateField(
        'bike', 'setup', 'test', 'Fork', 'Compression', '2 clicks');
    await edits.startTest('bike', 'setup', 'test', 'Ride');
    await edits.logRide(
        'bike', 'setup', 'test', const RideFeedback(feeling: 'Better'));
    final baseline = FirebaseFirestore.instance
        .doc('UserBikeSetup/${repo.uid}/Bikes/bike/setup/Fork');
    await baseline.update({'Compression': '5 clicks'});
    final result = await edits.finish('bike', 'setup', 'test', apply: true);
    expect(result.failure?.code, FailureCode.baselineChanged);
    expect((await baseline.get(const GetOptions(source: Source.server))).data(),
        {'Rebound': '6 clicks', 'Compression': '5 clicks'});
    expect((await serverTests(repo.uid)).single.stage, TestStage.review);
    final parent = await FirebaseFirestore.instance
        .doc(parentPath(repo.uid))
        .get(const GetOptions(source: Source.server));
    expect(parent.data()!['activeTestId'], 'test');
  });

  test('disposing a controller cancels its delayed mutation without writing',
      () async {
    final repo = await seed();
    final paused = PausedUpdate(repo);
    final edits = TestsController(paused, FakeSetupsRepository());
    final pending = edits.updateField(
        'bike', 'setup', 'test', 'Fork', 'Rebound', '8 clicks');
    await paused.entered.future;
    edits.dispose();
    paused.release.complete();
    expect((await pending).isCancelled, isTrue);
    expect((await serverTests(repo.uid)).single.values['Fork']!['Rebound'],
        '6 clicks');
  });
}
