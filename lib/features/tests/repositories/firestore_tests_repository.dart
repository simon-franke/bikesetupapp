import '../../setups/models/setup_configuration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/common/data/firebase_operation.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import '../models/setup_test.dart';
import 'tests_repository.dart';

class FirestoreTestsRepository implements TestsRepository {
  FirestoreTestsRepository(this.uid);
  final String uid;
  DocumentReference<Map<String, dynamic>> _bike(String bike) =>
      FirebaseFirestore.instance
          .collection('UserBikeSetup')
          .doc(uid)
          .collection('Bikes')
          .doc(bike);
  CollectionReference<Map<String, dynamic>> _tests(String bike, String setup) =>
      _bike(bike).collection('SetupList').doc(setup).collection('Tests');
  @override
  Stream<List<SetupTest>> watch(String bike, String setup) =>
      firebaseStream(_tests(bike, setup)
          .snapshots()
          .map((s) => s.docs.map((d) => SetupTest.fromMap(d.data())).toList()));
  @override
  Future<void> create(String bike, String setup, SetupTest test) =>
      _writeTransaction((tx) async {
        final parent = _bike(bike).collection('SetupList').doc(setup);
        final ref = _tests(bike, setup).doc(test.id);
        final baseline = await tx.get(parent);
        final saved = await tx.get(ref);
        if (!baseline.exists || saved.exists || test.stage != TestStage.draft) {
          throw const AppFailure(FailureCode.saveFailed);
        }
        return () {
          tx.set(ref, test.toMap());
        };
      });

  @override
  Future<void> update(String bike, String setup, String id,
          {required TestStage expectedStage,
          required SetupTest Function(SetupTest current) change}) =>
      _writeTransaction((tx) async {
        final parent = _bike(bike).collection('SetupList').doc(setup);
        final ref = _tests(bike, setup).doc(id);
        final baseline = await tx.get(parent);
        final saved = await tx.get(ref);
        if (!saved.exists || !baseline.exists) {
          throw const AppFailure(FailureCode.saveFailed);
        }
        final current = SetupTest.fromMap(saved.data()!);
        if (current.stage == TestStage.finished ||
            current.stage != expectedStage) {
          throw const AppFailure(FailureCode.saveFailed);
        }
        final updated = change(current);
        if (updated.id != id || updated.stage == TestStage.finished) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        return () => tx.set(ref, updated.toMap());
      });
  @override
  Future<void> finish(String bike, String setup, String id,
          {bool apply = false,
          String? newSetupId,
          String? newSetupName,
          bool onlyIfUnchanged = false}) =>
      _writeTransaction((tx) async {
        final testRef = _tests(bike, setup).doc(id);
        final saved = await tx.get(testRef);
        final parent = _bike(bike).collection('SetupList').doc(setup);
        final baseline = await tx.get(parent);
        if (!baseline.exists || !saved.exists) {
          throw const AppFailure(FailureCode.saveFailed);
        }
        final test = SetupTest.fromMap(saved.data()!);
        if (onlyIfUnchanged &&
            (test.stage != TestStage.draft || test.changes.isNotEmpty)) {
          return () {};
        }
        if (test.stage == TestStage.finished) return () {};
        if ((apply || newSetupId != null) && test.stage != TestStage.review) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        final categories = <String, Map<String, dynamic>>{};
        if (apply) {
          for (final category in test.values.keys) {
            final doc =
                await tx.get(_bike(bike).collection(setup).doc(category));
            categories[category] = doc.data() ?? {};
          }
        }
        if (apply) {
          for (final change in test.changes) {
            if ((categories[change.category]?[change.field]?.toString() ??
                    '') !=
                change.before) {
              throw const AppFailure(FailureCode.baselineChanged);
            }
          }
        }
        return () {
          if (apply) {
            for (final change in test.changes) {
              tx.set(_bike(bike).collection(setup).doc(change.category),
                  {change.field: change.after}, SetOptions(merge: true));
            }
          }
          if (newSetupId != null) {
            tx.set(_bike(bike).collection('SetupList').doc(newSetupId), {
              ...?test.setupInformation,
              // Older experiments have no captured configuration. Reconstruct
              // their selected fields from the saved values, never today's setup.
              if (test.setupInformation == null)
                SetupConfiguration.metadataKey: SetupConfiguration({
                  for (final entry in test.values.entries)
                    entry.key: entry.value.keys.toList(),
                }).encode(),
              'setup_name': newSetupName
            });
            for (final entry in test.values.entries) {
              tx.set(_bike(bike).collection(newSetupId).doc(entry.key),
                  entry.value);
              tx.set(
                  _bike(bike).collection(newSetupId).doc('${entry.key}_meta'),
                  test.fieldMetadata[entry.key] ?? <String, String>{});
            }
          }
          // Remove the legacy single-test pointer only for its own test.
          if (baseline.data()?['activeTestId'] == id) {
            tx.update(parent, {'activeTestId': FieldValue.delete()});
          }
          if (test.stage == TestStage.draft && !apply && newSetupId == null) {
            tx.delete(testRef);
            return;
          }
          tx.set(
              testRef,
              test
                  .copyWith(
                      stage: TestStage.finished,
                      result: apply
                          ? 'Applied to baseline'
                          : newSetupId != null
                              ? 'Saved as $newSetupName'
                              : 'Baseline kept')
                  .toMap());
        };
      });

  /// Preparation performs reads and validation only. Rejected commands commit
  /// no writes, and their Dart failures never cross the web SDK's JS boundary.
  Future<void> _writeTransaction(
          Future<void Function()> Function(Transaction tx) prepare) =>
      firebaseOperation(() async {
        final result = await FirebaseFirestore.instance
            .runTransaction<CommandResult<void>>((tx) async {
          final void Function() write;
          try {
            write = await prepare(tx);
          } on AppFailure catch (failure) {
            return CommandFailure<void>(failure);
          } on CommandAborted {
            return const CommandCancelled<void>();
          }
          write();
          return const CommandSuccess<void>(null);
        });
        result.requireValue();
      }, fallback: FailureCode.saveFailed);
}
