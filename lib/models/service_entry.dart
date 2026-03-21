import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/database_service/firestore_keys.dart';

class ServiceEntry {
  final String id;
  final String componentId;
  final double mileageAtServiceKm;
  final DateTime date;
  final String? note;

  const ServiceEntry({
    required this.id,
    required this.componentId,
    required this.mileageAtServiceKm,
    required this.date,
    this.note,
  });

  factory ServiceEntry.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceEntry(
      id: doc.id,
      componentId: data[FirestoreKeys.componentId] as String? ?? '',
      mileageAtServiceKm:
          (data[FirestoreKeys.mileageAtServiceKm] as num?)?.toDouble() ?? 0.0,
      date: (data[FirestoreKeys.serviceDate] as Timestamp?)?.toDate() ??
          DateTime.now(),
      note: data[FirestoreKeys.serviceNote] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.componentId: componentId,
      FirestoreKeys.mileageAtServiceKm: mileageAtServiceKm,
      FirestoreKeys.serviceDate: Timestamp.fromDate(date),
      if (note != null) FirestoreKeys.serviceNote: note,
    };
  }
}
