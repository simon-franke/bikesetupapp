import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/database_service/firestore_keys.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/models/strava_bike.dart';

class ServiceDatabaseService {
  ServiceDatabaseService(this.userID);
  String userID;

  final CollectionReference userBikeSetup =
      FirebaseFirestore.instance.collection(FirestoreKeys.userBikeSetup);

  // --- ServiceComponent methods ---

  Stream<List<ServiceComponent>> getComponentsForBike(String bikeId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .where(FirestoreKeys.bikeId, isEqualTo: bikeId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ServiceComponent.fromSnapshot(d)).toList());
  }

  Future<void> addComponent(ServiceComponent component) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(component.id)
        .set(component.toMap(), SetOptions(merge: true));
  }

  Future<void> updateComponent(String componentId,
      {String? name, int? serviceIntervalKm}) {
    final Map<String, dynamic> updates = {};
    if (name != null) updates[FirestoreKeys.componentName] = name;
    if (serviceIntervalKm != null) {
      updates[FirestoreKeys.serviceIntervalKm] = serviceIntervalKm;
    }
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .update(updates);
  }

  Future<void> deleteComponent(String componentId) async {
    final entries = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .get();
    for (var doc in entries.docs) {
      await doc.reference.delete();
    }
    await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .delete();
  }

  // --- ServiceEntry methods ---

  Stream<List<ServiceEntry>> getEntriesForComponent(String componentId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .orderBy(FirestoreKeys.serviceDate, descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ServiceEntry.fromSnapshot(d)).toList());
  }

  Future<void> addServiceEntry(String componentId, ServiceEntry entry) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .doc(entry.id)
        .set(entry.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteServiceEntry(String componentId, String entryId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .doc(entryId)
        .delete();
  }

  Future<ServiceEntry?> getLatestEntryForComponent(String componentId) async {
    final snap = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .orderBy(FirestoreKeys.serviceDate, descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ServiceEntry.fromSnapshot(snap.docs.first);
  }

  // --- StravaBike methods ---

  Future<void> saveStravaBikes(List<StravaBike> bikes) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final bike in bikes) {
      final ref = userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.stravaBikes)
          .doc(bike.stravaGearId);
      batch.set(ref, bike.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Stream<List<StravaBike>> getStravaBikes() {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => StravaBike.fromSnapshot(d)).toList());
  }

  Future<void> linkStravaBike(String stravaGearId, String appBikeId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .doc(stravaGearId)
        .update({FirestoreKeys.linkedBikeId: appBikeId});
  }

  Future<void> unlinkStravaBike(String stravaGearId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .doc(stravaGearId)
        .update({FirestoreKeys.linkedBikeId: FieldValue.delete()});
  }

  Future<double?> getMileageForBike(String appBikeId) async {
    final snap = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.stravaBikes)
        .where(FirestoreKeys.linkedBikeId, isEqualTo: appBikeId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final bike = StravaBike.fromSnapshot(snap.docs.first);
    return bike.distanceKm;
  }

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
