import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/common/data/firestore_keys.dart';
import 'package:bikesetupapp/features/setups/models/bike_setup.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'setups_repository.dart';

class FirestoreSetupsRepository implements SetupsRepository {
  FirestoreSetupsRepository(this.userID, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final String userID;
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get userBikeSetup =>
      _firestore.collection(FirestoreKeys.userBikeSetup);
  @override
  Future<void> createSetupList(String uBikeID, String uSetupID,
      String setupName, Map<String, dynamic> setupInformation) {
    final Map<String, dynamic> setupListDocument = <String, dynamic>{};
    setupListDocument.addAll(setupInformation);
    setupListDocument[FirestoreKeys.setupName] = setupName;

    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .doc(uSetupID)
        .set(setupListDocument, SetOptions(merge: true));
  }

  @override
  Future<void> setDefaultSetup(String uBikeID, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .set({FirestoreKeys.defaultSetup: uSetupID}, SetOptions(merge: true));
  }

  @override
  Future<void> setSetting(String key, String value, String uBikeID,
      String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .set({key: value}, SetOptions(merge: true));
  }

  @override
  Future<void> editSetting(String key, String value, String uBikeID,
      String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .update({key: value});
  }

  @override
  Future<void> deleteSetup(String uBikeID, String uSetupID) async {
    // If deleting the default setup, auto-reassign to another setup
    final currentDefault = await getDefaultSetup(uBikeID);
    if (currentDefault == uSetupID) {
      final setupList = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .collection(FirestoreKeys.setupList)
          .get();
      final others = setupList.docs.where((d) => d.id != uSetupID).toList();
      if (others.isNotEmpty) {
        await setDefaultSetup(uBikeID, others.first.id);
      }
    }

    await _deleteSetupData(uBikeID, uSetupID);
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
  Future<void> deleteSetting(
      String key, String uBikeID, String category, String uSetupID) async {
    await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .update({
      key: FieldValue.delete(),
    });
  }

  @override
  Future<void> setSettingMeta(String key, String familyName, String uBikeID,
      String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc('${category}_meta')
        .set({key: familyName}, SetOptions(merge: true));
  }

  @override
  Future<void> deleteSettingMeta(
      String key, String uBikeID, String category, String uSetupID) async {
    final ref = userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc('${category}_meta');
    final snap = await ref.get();
    if (snap.exists) {
      await ref.update({key: FieldValue.delete()});
    }
  }

  @override
  Stream<Map<String, dynamic>> getSettingsMeta(
      String uBikeID, String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc('${category}_meta')
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  @override
  Stream<Map<String, dynamic>> getSettings(
      String uBikeID, String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  @override
  Stream<List<BikeSetup>> getSetups(String uBikeID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BikeSetup.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<Map<String, dynamic>> getDocumentElement(
      String uBikeID, String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  @override
  Future<String> getDefaultSetup(String uBikeID) async {
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
      value = snapshot[FirestoreKeys.defaultSetup];
    } catch (e) {
      debugPrint('getDefaultSetup error: $e');
      return "";
    }
    return value.toString();
  }

  @override
  Future<String> getSetupNameFromID(String uBikeID, String uSetupID) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    dynamic value;
    try {
      snapshot = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .collection(FirestoreKeys.setupList)
          .doc(uSetupID)
          .get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.setupName];
    } catch (e) {
      debugPrint('getSetupNameFromID error: $e');
      return "";
    }
    if (value == null) {
      return "";
    }
    return value.toString();
  }

  @override
  Future<Map<String, dynamic>> getSetupInformation(
      String uBikeID, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .doc(uSetupID)
        .get()
        .then((snapshot) => snapshot.data() ?? {});
  }

  @override
  Future<Map<String, dynamic>> getSetupInformationAsMap(
      String uBikeID, String uSetupID) {
    return getSetupInformation(uBikeID, uSetupID);
  }
}
