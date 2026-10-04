import 'package:bikesetupapp/common/data/firebase_operation.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/common/data/firestore_keys.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'bikes_repository.dart';

class FirestoreBikesRepository implements BikesRepository {
  FirestoreBikesRepository(this.userID, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final String userID;
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get userBikeSetup =>
      _firestore.collection(FirestoreKeys.userBikeSetup);
  @override
  Future<void> setDefaultBike(String uBikeID) {
    return firebaseOperation(() async {
      return userBikeSetup
          .doc(userID)
          .set({FirestoreKeys.defaultBike: uBikeID}, SetOptions(merge: true));
    }, fallback: FailureCode.saveFailed);
  }

  @override
  Future<void> renameBike(String uBikeID, String bikeName) {
    return firebaseOperation(() async {
      return userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .update({FirestoreKeys.bikeName: bikeName});
    }, fallback: FailureCode.saveFailed);
  }

  @override
  Future<void> deleteBike(String uBikeID) async {
    return firebaseOperation(() async {
      final wasDefault = (await getDefaultBike()) == uBikeID;

      var setups = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .collection(FirestoreKeys.setupList)
          .get();
      for (var doc in setups.docs) {
        await _deleteSetupData(uBikeID, doc.id);
      }

      await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .delete();

      if (wasDefault) {
        final remaining = await userBikeSetup
            .doc(userID)
            .collection(FirestoreKeys.bikes)
            .get();
        if (remaining.docs.isNotEmpty) {
          await setDefaultBike(remaining.docs.first.id);
        } else {
          await userBikeSetup
              .doc(userID)
              .update({FirestoreKeys.defaultBike: FieldValue.delete()});
        }
      }
    }, fallback: FailureCode.saveFailed);
  }

  Future<void> _deleteSetupData(String uBikeID, String uSetupID) async {
    var setups = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .get();

    for (var doc in setups.docs) {
      await doc.reference.delete();
    }

    await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .doc(uSetupID)
        .delete();
  }

  @override
  Stream<List<Bike>> getBikes() {
    return firebaseStream(userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bike.fromMap(doc.id, doc.data()))
            .toList()));
  }

  @override
  Future<String> getDefaultBike() async {
    return firebaseOperation(() async {
      DocumentSnapshot<Map<String, dynamic>> snapshot;
      dynamic value;
      snapshot = await userBikeSetup.doc(userID).get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot.data()?[FirestoreKeys.defaultBike];

      if (value == null) {
        return "";
      }
      return value?.toString() ?? "";
    });
  }

  @override
  Future<String> getBikeNameFromID(String uBikeID) async {
    return firebaseOperation(() async {
      DocumentSnapshot<Map<String, dynamic>> snapshot;
      dynamic value;
      snapshot = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot.data()?[FirestoreKeys.bikeName];

      if (value == null) {
        return "";
      }
      return value?.toString() ?? "";
    });
  }

  @override
  Future<String> getBikeType(String uBikeID) async {
    return firebaseOperation(() async {
      DocumentSnapshot<Map<String, dynamic>> snapshot;
      dynamic value;
      snapshot = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot.data()?[FirestoreKeys.bikeType];

      if (value == null) {
        return "";
      }
      return value?.toString() ?? "";
    });
  }

  @override
  Future<void> createBikeRecord(String id, String name, String type) {
    return firebaseOperation(() async {
      return userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(id)
          .set({FirestoreKeys.bikeName: name, FirestoreKeys.bikeType: type},
              SetOptions(merge: true));
    }, fallback: FailureCode.saveFailed);
  }
}
