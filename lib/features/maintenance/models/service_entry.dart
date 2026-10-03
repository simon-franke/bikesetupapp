import 'package:bikesetupapp/common/data/firestore_keys.dart';

class ServiceEntry {
  final String id;
  final String componentId;
  final double?
      mileageAtServiceKm; // null when mileage at service time is unknown
  final DateTime date;
  final String? note;

  const ServiceEntry({
    required this.id,
    required this.componentId,
    this.mileageAtServiceKm,
    required this.date,
    this.note,
  });

  factory ServiceEntry.fromMap(String id, Map<String, dynamic> data) {
    return ServiceEntry(
      id: id,
      componentId: data[FirestoreKeys.componentId] as String? ?? '',
      mileageAtServiceKm:
          (data[FirestoreKeys.mileageAtServiceKm] as num?)?.toDouble(),
      date: (data[FirestoreKeys.serviceDate] as DateTime?) ?? DateTime.now(),
      note: data[FirestoreKeys.serviceNote] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.componentId: componentId,
      if (mileageAtServiceKm != null)
        FirestoreKeys.mileageAtServiceKm: mileageAtServiceKm,
      FirestoreKeys.serviceDate: date,
      if (note != null) FirestoreKeys.serviceNote: note,
    };
  }
}
