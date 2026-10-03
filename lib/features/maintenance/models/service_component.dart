import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/common/data/firestore_keys.dart';

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

  factory ServiceComponent.fromMap(String id, Map<String, dynamic> data) {
    return ServiceComponent(
      id: id,
      bikeId: data[FirestoreKeys.bikeId] as String? ?? '',
      type: ComponentType.fromString(
          data[FirestoreKeys.componentType] as String? ?? ''),
      name: data[FirestoreKeys.componentName] as String? ?? '',
      serviceIntervalKm:
          (data[FirestoreKeys.serviceIntervalKm] as num?)?.toInt() ?? 0,
      createdAt: (data[FirestoreKeys.createdAt] as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.bikeId: bikeId,
      FirestoreKeys.componentType: type.name,
      FirestoreKeys.componentName: name,
      FirestoreKeys.serviceIntervalKm: serviceIntervalKm,
      FirestoreKeys.createdAt: createdAt,
    };
  }
}
