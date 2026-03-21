import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/bike_enums/component_type.dart';
import 'package:bikesetupapp/database_service/firestore_keys.dart';

class ServiceComponent {
  final String id;
  final String bikeId;
  final ComponentType type;
  final String name;
  final int serviceIntervalKm;
  final DateTime createdAt;

  const ServiceComponent({
    required this.id,
    required this.bikeId,
    required this.type,
    required this.name,
    required this.serviceIntervalKm,
    required this.createdAt,
  });

  factory ServiceComponent.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceComponent(
      id: doc.id,
      bikeId: data[FirestoreKeys.bikeId] as String? ?? '',
      type: ComponentType.fromString(
          data[FirestoreKeys.componentType] as String? ?? ''),
      name: data[FirestoreKeys.componentName] as String? ?? '',
      serviceIntervalKm:
          (data[FirestoreKeys.serviceIntervalKm] as num?)?.toInt() ?? 0,
      createdAt:
          (data[FirestoreKeys.createdAt] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.bikeId: bikeId,
      FirestoreKeys.componentType: type.name,
      FirestoreKeys.componentName: name,
      FirestoreKeys.serviceIntervalKm: serviceIntervalKm,
      FirestoreKeys.createdAt: Timestamp.fromDate(createdAt),
    };
  }
}
