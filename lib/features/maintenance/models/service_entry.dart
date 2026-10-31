import 'package:bikesetupapp/common/data/firestore_keys.dart';

class ServiceEntry {
  final String id;
  final String componentId;
  final double?
      mileageAtServiceKm; // null when mileage at service time is unknown
  final double? initialRideHours;
  final double? initialDistanceKm;
  final DateTime date;
  final String? note;

  const ServiceEntry({
    required this.id,
    required this.componentId,
    this.mileageAtServiceKm,
    required this.date,
    this.note,
    this.initialRideHours,
    this.initialDistanceKm,
  });

  factory ServiceEntry.fromMap(String id, Map<String, dynamic> data) {
    return ServiceEntry(
      id: id,
      componentId: data[FirestoreKeys.componentId] as String? ?? '',
      mileageAtServiceKm:
          (data[FirestoreKeys.mileageAtServiceKm] as num?)?.toDouble(),
      date: (data[FirestoreKeys.serviceDate] as DateTime?) ?? DateTime.now(),
      initialDistanceKm: (data['initialDistanceKm'] as num?)?.toDouble(),
      initialRideHours: (data['initialRideHours'] as num?)?.toDouble(),
      note: data[FirestoreKeys.serviceNote] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.componentId: componentId,
      if (mileageAtServiceKm != null)
        FirestoreKeys.mileageAtServiceKm: mileageAtServiceKm,
      FirestoreKeys.serviceDate: date,
      if (initialDistanceKm != null) 'initialDistanceKm': initialDistanceKm,
      if (initialRideHours != null) 'initialRideHours': initialRideHours,
      if (note != null) FirestoreKeys.serviceNote: note,
    };
  }
}
