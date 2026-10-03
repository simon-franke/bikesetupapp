import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/common/data/firestore_keys.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/common/data/firestore_codec.dart';
import 'maintenance_repository.dart';

class FirestoreMaintenanceRepository implements MaintenanceRepository {
  FirestoreMaintenanceRepository(this.userID, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final String userID;
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get userBikeSetup =>
      _firestore.collection(FirestoreKeys.userBikeSetup);
  @override
  Stream<List<ServiceComponent>> getComponentsForBike(String bikeId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .where(FirestoreKeys.bikeId, isEqualTo: bikeId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ServiceComponent.fromMap(d.id, decodeFirestoreMap(d.data())))
            .toList());
  }

  @override
  Future<void> addComponent(ServiceComponent component) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(component.id)
        .set(encodeFirestoreMap(component.toMap()), SetOptions(merge: true));
  }

  @override
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

  @override
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

  @override
  Stream<List<ServiceEntry>> getEntriesForComponent(String componentId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .orderBy(FirestoreKeys.serviceDate, descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(
                (d) => ServiceEntry.fromMap(d.id, decodeFirestoreMap(d.data())))
            .toList());
  }

  @override
  Future<void> addServiceEntry(String componentId, ServiceEntry entry) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .doc(entry.id)
        .set(encodeFirestoreMap(entry.toMap()), SetOptions(merge: true));
  }

  @override
  Future<void> deleteServiceEntry(String componentId, String entryId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .doc(entryId)
        .delete();
  }

  @override
  Stream<ServiceEntry?> streamLatestEntryForComponent(String componentId) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.serviceComponents)
        .doc(componentId)
        .collection(FirestoreKeys.serviceEntries)
        .orderBy(FirestoreKeys.serviceDate, descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : ServiceEntry.fromMap(snap.docs.first.id,
                decodeFirestoreMap(snap.docs.first.data())));
  }

  @override
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
    return ServiceEntry.fromMap(
        snap.docs.first.id, decodeFirestoreMap(snap.docs.first.data()));
  }
}
