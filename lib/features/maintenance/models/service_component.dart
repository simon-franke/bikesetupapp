import 'service_icon.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/common/data/firestore_keys.dart';

class ServiceComponent {
  final String id;
  final String bikeId;
  final ComponentType type;
  final String name;
  final ServiceIcon? customIcon;
  final int serviceIntervalKm;
  final double? serviceIntervalHours;
  final bool includeIndoorRides;
  bool get usesHours => serviceIntervalHours != null;
  double get interval => serviceIntervalHours ?? serviceIntervalKm.toDouble();
  String get unitLabel => usesHours ? 'ride hours' : 'km';
  final DateTime createdAt;

  const ServiceComponent({
    required this.id,
    required this.bikeId,
    required this.type,
    required this.name,
    required this.serviceIntervalKm,
    required this.createdAt,
    this.serviceIntervalHours,
    this.customIcon,
    this.includeIndoorRides = false,
  });

  factory ServiceComponent.fromMap(String id, Map<String, dynamic> data) {
    return ServiceComponent(
      id: id,
      bikeId: data[FirestoreKeys.bikeId] as String? ?? '',
      type: ComponentType.fromString(
          data[FirestoreKeys.componentType] as String? ?? ''),
      customIcon: ServiceIcon.fromName(data['customIcon'] as String?),
      name: data[FirestoreKeys.componentName] as String? ?? '',
      serviceIntervalKm:
          (data[FirestoreKeys.serviceIntervalKm] as num?)?.toInt() ?? 0,
      serviceIntervalHours: (data['serviceIntervalHours'] as num?)?.toDouble(),
      includeIndoorRides: data['includeIndoorRides'] as bool? ?? false,
      createdAt: (data[FirestoreKeys.createdAt] as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (customIcon != null) 'customIcon': customIcon!.name,
      FirestoreKeys.bikeId: bikeId,
      FirestoreKeys.componentType: type.name,
      FirestoreKeys.componentName: name,
      FirestoreKeys.serviceIntervalKm: serviceIntervalKm,
      FirestoreKeys.createdAt: createdAt,
      if (serviceIntervalHours != null)
        'serviceIntervalHours': serviceIntervalHours,
      'includeIndoorRides': includeIndoorRides,
    };
  }
}
