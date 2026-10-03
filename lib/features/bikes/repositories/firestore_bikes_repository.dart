import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/common/data/firestore_keys.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
    return userBikeSetup
        .doc(userID)
        .set({FirestoreKeys.defaultBike: uBikeID}, SetOptions(merge: true));
  }

  @override
  Future<void> renameBike(String uBikeID, String bikeName) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .update({FirestoreKeys.bikeName: bikeName});
  }

  @override
  Future<void> deleteBike(String uBikeID) async {
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
      final remaining =
          await userBikeSetup.doc(userID).collection(FirestoreKeys.bikes).get();
      if (remaining.docs.isNotEmpty) {
        await setDefaultBike(remaining.docs.first.id);
      } else {
        await userBikeSetup
            .doc(userID)
            .update({FirestoreKeys.defaultBike: FieldValue.delete()});
      }
    }
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
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bike.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<String> getDefaultBike() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    dynamic value;
    try {
      snapshot = await userBikeSetup.doc(userID).get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.defaultBike];
    } catch (e) {
      debugPrint('getDefaultBike error: $e');
      return "";
    }
    if (value == null) {
      return "";
    }
    return value.toString();
  }

  @override
  Future<String> getBikeNameFromID(String uBikeID) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    dynamic value;
    try {
      snapshot = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.bikeName];
    } catch (e) {
      debugPrint('getBikeNameFromID error: $e');
      return "";
    }

    if (value == null) {
      return "";
    }
    return value.toString();
  }

  @override
  Future<String> getBikeType(String uBikeID) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    dynamic value;
    try {
      snapshot = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.bikeType];
    } catch (e) {
      debugPrint('getBikeType error: $e');
      return "";
    }
    if (value == null) {
      return "";
    }
    return value.toString();
  }

  @override
  Future<void> createBikeRecord(String id, String name, String type) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(id)
        .set({FirestoreKeys.bikeName: name, FirestoreKeys.bikeType: type},
            SetOptions(merge: true));
  }
}
