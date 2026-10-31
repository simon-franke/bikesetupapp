import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/common/data/firestore_codec.dart';
import 'package:bikesetupapp/common/data/firebase_operation.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import '../models/ride.dart';
import 'rides_repository.dart';

class FirestoreRidesRepository implements RidesRepository {
  FirestoreRidesRepository(this.uid);
  final String uid;
  CollectionReference<Map<String, dynamic>> get _rides =>
      FirebaseFirestore.instance
          .collection('UserBikeSetup')
          .doc(uid)
          .collection('RideLog');
  @override
  Stream<List<Ride>> watch(String bikeId) => firebaseStream(_rides
      .where('bikeId', isEqualTo: bikeId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Ride.fromMap(d.id, decodeFirestoreMap(d.data())))
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt))));
  @override
  Future<int> insert(List<Ride> rides) => firebaseOperation(
      () => FirebaseFirestore.instance.runTransaction((tx) async {
            final unique = {for (final ride in rides) ride.id: ride};
            final missing = <Ride>[];
            for (final ride in unique.values) {
              if (!(await tx.get(_rides.doc(ride.id))).exists) {
                missing.add(ride);
              }
            }
            for (final ride in missing) {
              tx.set(_rides.doc(ride.id), encodeFirestoreMap(ride.toMap()));
            }
            return missing.length;
          }),
      fallback: FailureCode.saveFailed);
  @override
  Future<void> remove(String id) =>
      firebaseOperation(() => _rides.doc(id).delete(),
          fallback: FailureCode.saveFailed);
}
