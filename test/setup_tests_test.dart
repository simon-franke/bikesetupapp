import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/tests/controllers/tests_controller.dart';
import 'package:bikesetupapp/features/tests/models/setup_test.dart';
import 'package:bikesetupapp/features/tests/repositories/tests_repository.dart';
import 'package:bikesetupapp/features/tests/ui/tests_view.dart';
import 'support/fake_repositories.dart';

class MemoryTests implements TestsRepository {
  final records = <String, SetupTest>{};
  final updates = StreamController<void>.broadcast();
  bool fail = false;
  bool applied = false;
  @override
  Stream<List<SetupTest>> watch(String bike, String setup) async* {
    yield records.values.toList();
    await for (final _ in updates.stream) {
      yield records.values.toList();
    }
  }

  @override
  Future<void> save(String bike, String setup, SetupTest test) async {
    if (fail) throw const AppFailure(FailureCode.saveFailed);
    records[test.id] = test;
    updates.add(null);
  }

  @override
  Future<void> finish(String bike, String setup, SetupTest test,
      {bool apply = false, String? newSetupId, String? newSetupName}) async {
    if (fail) throw const AppFailure(FailureCode.saveFailed);
    applied = apply;
    await save(bike, setup,
        test.copyWith(stage: TestStage.finished, result: 'Baseline kept'));
  }
}

SetupTest sample({TestStage stage = TestStage.draft}) =>
    SetupTest(id: 'test', name: 'Roots and braking', stage: stage, before: {
      'FrontTire': {'Pressure': '22 psi'},
      'Fork': {'Compression': '6 clicks'}
    }, values: {
      'FrontTire': {'Pressure': '21 psi'},
      'Fork': {'Compression': '4 clicks'}
    });

void main() {
  test(
      'configured tests preserve selected parts without adding air fields to a coil fork',
      () async {
    final repo = MemoryTests();
    final setups = FakeSetupsRepository();
    final configuration = SetupConfiguration({
      'FrontTire': ['Pressure'],
      'RearTire': ['Pressure'],
      'Fork': ['Spring Rate', 'Preload', 'Sag', 'Rebound'],
      'GeneralSettings': ['Stem length', 'Seat Height'],
    });
    setups.information['setup'] = {
      SetupConfiguration.metadataKey: configuration.encode()
    };
    setups.settings['bike/setup/Fork/Spring Rate'] = '65 N/mm';
    final controller = TestsController(repo, setups);
    final result = await controller.create('bike', 'setup', 'Coil',
        ['FrontTire', 'RearTire', 'Fork', 'Shock', 'GeneralSettings']);
    expect(result.isSuccess, isTrue);
    final draft = repo.records.values.single;
    expect(draft.values.keys.toSet(), configuration.fields.keys.toSet());
    expect(draft.values['Fork']!['Spring Rate'], '65 N/mm');
    expect(draft.values['Fork']!.containsKey('Pressure'), isFalse);
    expect(draft.values['GeneralSettings']!.containsKey('Reach'), isFalse);
    controller.dispose();
    await repo.updates.close();
  });

  test('test snapshots preserve baseline and round-trip multi-setting changes',
      () async {
    final repo = MemoryTests();
    final setups = FakeSetupsRepository();
    setups.settings['bike/setup/FrontTire/Pressure'] = '22 psi';
    setups.settings['bike/setup/Fork/Compression'] = '6 clicks';
    final controller = TestsController(repo, setups);
    expect(
        (await controller
                .create('bike', 'setup', 'Dry trails', ['FrontTire', 'Fork']))
            .isSuccess,
        isTrue);
    final draft = repo.records.values.single;
    await Future.wait([
      controller.updateField(
          'bike', 'setup', draft.id, 'FrontTire', 'Pressure', '21 psi'),
      controller.updateField(
          'bike', 'setup', draft.id, 'Fork', 'Compression', '4 clicks'),
    ]);
    final restored = SetupTest.fromMap(repo.records.values.single.toMap());
    expect(restored.changes, hasLength(2));
    expect(restored.before['FrontTire']!['Pressure'], '22 psi');
    expect(setups.settings['bike/setup/FrontTire/Pressure'], '22 psi');
    await controller.create('bike', 'setup', 'Duplicate', ['FrontTire']);
    expect(repo.records, hasLength(1));
    await controller.startTest('bike', 'setup', restored.id, restored.name);
    await controller.logRide('bike', 'setup', restored.id,
        const RideFeedback(feeling: 'Better'));
    repo.fail = true;
    expect(
        (await controller.finish('bike', 'setup', restored.id, apply: true))
            .isSuccess,
        isFalse);
    expect(repo.records.values.single.stage, TestStage.review);
    repo.fail = false;
    expect((await controller.finish('bike', 'setup', restored.id)).isSuccess,
        isTrue);
    expect(repo.applied, isFalse);
    controller.dispose();
    await repo.updates.close();
  });

  test('test commands enforce transitions and preserve queued changes',
      () async {
    final repo = MemoryTests();
    repo.records['test'] = sample();
    final controller = TestsController(repo, FakeSetupsRepository());
    addTearDown(controller.dispose);
    addTearDown(repo.updates.close);
    expect((await controller.resumeTest('bike', 'setup', 'test')).isSuccess,
        isFalse);
    await Future.wait([
      controller.renameDraft('bike', 'setup', 'test', 'Renamed'),
      controller.updateField(
          'bike', 'setup', 'test', 'Fork', 'Compression', '3 clicks'),
      controller.startTest('bike', 'setup', 'test', 'Renamed'),
    ]);
    expect(repo.records['test']!.values['Fork']!['Compression'], '3 clicks');
    expect(repo.records['test']!.stage, TestStage.ride);
    expect(
        (await controller.updateField(
                'bike', 'setup', 'test', 'Fork', 'Compression', '9 clicks'))
            .isSuccess,
        isFalse);
    expect(
        (await controller.logRide('bike', 'setup', 'test',
                const RideFeedback(feeling: 'Better', time: '03:99')))
            .isSuccess,
        isFalse);
    expect(repo.records['test']!.rides, isEmpty);
    expect(
        (await controller.logRide(
                'bike',
                'setup',
                'test',
                const RideFeedback(
                    feeling: 'Better', note: ' Grip ', time: '03:42')))
            .isSuccess,
        isTrue);
    expect(repo.records['test']!.rides.single.note, 'Grip');
    expect(
        (await controller.logRide(
                'bike', 'setup', 'test', const RideFeedback(feeling: 'Same')))
            .isSuccess,
        isFalse);
    await controller.resumeTest('bike', 'setup', 'test');
    await controller.logRide(
        'bike', 'setup', 'test', const RideFeedback(feeling: 'Same'));
    expect(repo.records['test']!.rides, hasLength(2));
    await controller.finish('bike', 'setup', 'test');
    expect((await controller.resumeTest('bike', 'setup', 'test')).isSuccess,
        isFalse);
  });

  test('typed feedback preserves the stored map format', () {
    final data = sample(stage: TestStage.review).copyWith(rides: [
      const RideFeedback(feeling: 'Better', note: 'Grip', time: '03:42')
    ]).toMap();
    expect(data['stage'], 'review');
    expect((data['rides'] as List).single,
        {'feeling': 'Better', 'note': 'Grip', 'time': '03:42'});
    final restored = SetupTest.fromMap(data);
    expect(restored.stage, TestStage.review);
    expect(restored.rides.single.validationError, isNull);
    expect(restored.toMap(), data);
  });

  testWidgets(
      'ride feedback validates time, records multiple rides and finishes safely',
      (tester) async {
    tester.view.physicalSize = const Size(404, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryTests();
    repo.records['test'] = sample(stage: TestStage.ride);
    final deps = AppDependencies(
        testsRepository: (_) => repo,
        setupsRepository: (_) => FakeSetupsRepository());
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
                body: TestsView(
              uid: 'user',
              bike: 'bike',
              setup: 'setup',
              setupName: 'Dry trails',
            )))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log ride'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Better, Same or Worse.'), findsOneWidget);
    await tester.tap(find.text('Better'));
    await tester.enterText(find.byType(TextField).last, '03:99');
    await tester.tap(find.text('Log ride'));
    await tester.pumpAndSettle();
    expect(find.text('Use minutes:seconds, e.g. 03:42.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'More grip on roots.');
    await tester.enterText(find.byType(TextField).last, '03:42');
    await tester.tap(find.text('Log ride'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.stage, TestStage.review);
    expect(find.text('More grip on roots.'), findsOneWidget);
    expect(repo.records['test']!.rides.single.time, '03:42');
    await tester.tap(find.text('Log another ride'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Same'));
    await tester.tap(find.text('Log ride'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.rides, hasLength(2));
    await tester.ensureVisible(find.text('Finish without changes'));
    await tester.tap(find.text('Finish without changes'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.stage, TestStage.finished);
    expect(repo.applied, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    await repo.updates.close();
  });

  for (final stage in [TestStage.draft, TestStage.ride, TestStage.review]) {
    testWidgets('$stage fits narrow screens with enlarged text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryTests();
      repo.records['test'] = sample(stage: stage);
      final deps = AppDependencies(
          testsRepository: (_) => repo,
          setupsRepository: (_) => FakeSetupsRepository());
      await tester.pumpWidget(Provider.value(
          value: deps,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: const Scaffold(
                      body: TestsView(
                    uid: 'user',
                    bike: 'bike',
                    setup: 'setup',
                    setupName: 'Dry trails',
                  ))))));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      deps.dispose();
      await repo.updates.close();
    });
  }
}
