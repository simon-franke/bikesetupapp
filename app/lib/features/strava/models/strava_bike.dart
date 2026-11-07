import 'package:bikesetupapp/common/data/firestore_keys.dart';

class StravaBike {
  final String stravaGearId;
  final String name;
  final double distanceMeters;
  final String? linkedBikeId;

  const StravaBike({
    required this.stravaGearId,
    required this.name,
    required this.distanceMeters,
    this.linkedBikeId,
  });

  double get distanceKm => distanceMeters / 1000;

  factory StravaBike.fromMap(String id, Map<String, dynamic> data) {
    return StravaBike(
      stravaGearId: id,
      name: data[FirestoreKeys.stravaBikeName] as String? ?? '',
      distanceMeters:
          (data[FirestoreKeys.distanceMeters] as num?)?.toDouble() ?? 0.0,
      linkedBikeId: data[FirestoreKeys.linkedBikeId] as String?,
    );
  }

  factory StravaBike.fromStravaJson(Map<String, dynamic> json) {
    return StravaBike(
      stravaGearId: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.stravaBikeName: name,
      FirestoreKeys.distanceMeters: distanceMeters,
      if (linkedBikeId != null) FirestoreKeys.linkedBikeId: linkedBikeId,
    };
  }
}
