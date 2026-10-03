import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/common/data/firestore_keys.dart';
import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
import 'package:bikesetupapp/common/data/firestore_codec.dart';
import 'strava_bikes_repository.dart';

class FirestoreStravaBikesRepository implements StravaBikesRepository {
  FirestoreStravaBikesRepository(this.userID, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final String userID;
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get userBikeSetup =>
      _firestore.collection(FirestoreKeys.userBikeSetup);
  @override
  Future<void> saveStravaBikes(List<StravaBike> bikes) async {
    final batch = _firestore.batch();
    for (final bike in bikes) {
      final ref = userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.stravaBikes)
          .doc(bike.stravaGearId);
      batch.set(ref, encodeFirestoreMap(bike.toMap()), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Stream<List<StravaBike>> getStravaBikes() {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StravaBike.fromMap(d.id, decodeFirestoreMap(d.data())))
            .toList());
  }

  @override
  Future<void> linkStravaBike(String stravaGearId, String appBikeId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .doc(stravaGearId)
        .update({FirestoreKeys.linkedBikeId: appBikeId});
  }

  @override
  Future<void> unlinkStravaBike(String stravaGearId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .doc(stravaGearId)
        .update({FirestoreKeys.linkedBikeId: FieldValue.delete()});
  }

  @override
  Future<String?> getStravaGearIdForBike(String appBikeId) async {
    final snap = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .where(FirestoreKeys.linkedBikeId, isEqualTo: appBikeId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  @override
  Future<double?> getMileageForBike(String appBikeId) async {
    final snap = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .where(FirestoreKeys.linkedBikeId, isEqualTo: appBikeId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final bike = StravaBike.fromMap(
        snap.docs.first.id, decodeFirestoreMap(snap.docs.first.data()));
    return bike.distanceKm;
  }

  @override
  Future<void> deleteAllStravaBikes() async {
    final snap = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
