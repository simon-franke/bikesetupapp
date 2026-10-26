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
  Future<void> save(String bike, String setup, SetupTest test) =>
      firebaseOperation(
          () => FirebaseFirestore.instance.runTransaction((tx) async {
                final parent = _bike(bike).collection('SetupList').doc(setup);
                final ref = _tests(bike, setup).doc(test.id);
                final baseline = await tx.get(parent);
                final saved = await tx.get(ref);
                if (!baseline.exists ||
                    saved.data()?['stage'] == 'finished' ||
                    (!saved.exists &&
                        baseline.data()?['activeTestId'] != null)) {
                  throw const AppFailure(FailureCode.saveFailed);
                }
                tx.set(ref, test.toMap());
                tx.update(parent, {'activeTestId': test.id});
              }),
          fallback: FailureCode.saveFailed);
  @override
  Future<void> finish(String bike, String setup, SetupTest test,
          {bool apply = false, String? newSetupId, String? newSetupName}) =>
      firebaseOperation(() async {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final testRef = _tests(bike, setup).doc(test.id);
          final saved = await tx.get(testRef);
          final parent = _bike(bike).collection('SetupList').doc(setup);
          final baseline = await tx.get(parent);
          if (!baseline.exists || !saved.exists) {
            throw const AppFailure(FailureCode.saveFailed);
          }
          if (saved.data()?['stage'] == 'finished') return;
          final categories = <String, Map<String, dynamic>>{};
          final metadata = <String, Map<String, dynamic>>{};
          if (apply || newSetupId != null) {
            for (final category in test.values.keys) {
              final doc =
                  await tx.get(_bike(bike).collection(setup).doc(category));
              categories[category] = doc.data() ?? {};
              if (newSetupId != null) {
                final meta = await tx
                    .get(_bike(bike).collection(setup).doc('${category}_meta'));
                metadata[category] = meta.data() ?? {};
              }
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
            for (final change in test.changes) {
              tx.set(_bike(bike).collection(setup).doc(change.category),
                  {change.field: change.after}, SetOptions(merge: true));
            }
          }
          if (newSetupId != null) {
            tx.set(_bike(bike).collection('SetupList').doc(newSetupId), {
              for (final e in baseline.data()!.entries)
                if (e.key != 'activeTestId') e.key: e.value,
              'setup_name': newSetupName
            });
            for (final entry in test.values.entries) {
              tx.set(_bike(bike).collection(newSetupId).doc(entry.key),
                  entry.value);
              tx.set(
                  _bike(bike).collection(newSetupId).doc('${entry.key}_meta'),
                  metadata[entry.key]!);
            }
          }
          tx.update(parent, {'activeTestId': FieldValue.delete()});
          if (test.stage == 'draft' && !apply && newSetupId == null) {
            tx.delete(testRef);
            return;
          }
          tx.set(
              testRef,
              test
                  .copyWith(
                      stage: 'finished',
                      result: apply
                          ? 'Applied to baseline'
                          : newSetupId != null
                              ? 'Saved as $newSetupName'
                              : 'Baseline kept')
                  .toMap());
        });
      }, fallback: FailureCode.saveFailed);
}
