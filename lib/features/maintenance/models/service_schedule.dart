import '../../rides/models/ride.dart';
import 'service_component.dart';
import 'service_entry.dart';

enum ServiceStatus { red, amber, green, unknown }

enum ServiceUnit { kilometres, hours }

class ServiceUsage {
  const ServiceUsage(
      {required this.unit,
      required this.used,
      required this.interval,
      required this.available});
  final ServiceUnit unit;
  final double used, interval;
  final bool available;
  double get remaining => (interval - used).clamp(0, double.infinity);
  double get progress => available && interval > 0 ? used / interval : 0;
  ServiceStatus get status {
    if (!available) return ServiceStatus.unknown;
    if (progress >= 0.9) return ServiceStatus.red;
    if (progress >= 0.7) return ServiceStatus.amber;
    return ServiceStatus.green;
  }
}

class AnnotatedService {
  const AnnotatedService(
      {required this.component,
      required this.measurement,
      required this.lastServicedAt});
  final ServiceComponent component;
  final ServiceUsage measurement;
  final DateTime? lastServicedAt;
  double get usage => measurement.used;
  double get remaining => measurement.remaining;
  double get progress => measurement.progress;
  ServiceStatus get status => measurement.status;
  bool get usageUnknown => !measurement.available;
}

AnnotatedService annotateService({
  required ServiceComponent component,
  required double currentMileageKm,
  required ServiceEntry? latestEntry,
  bool mileageAvailable = true,
  List<Ride>? rides,
}) {
  final ServiceUsage measurement;
  if (component.usesHours) {
    measurement = ServiceUsage(
      unit: ServiceUnit.hours,
      used: latestEntry != null && rides != null
          ? (latestEntry.initialRideHours ?? 0) +
              hoursSince(rides, latestEntry.date,
                  includeIndoor: component.includeIndoorRides)
          : 0,
      interval: component.interval,
      available: rides != null && latestEntry != null && component.interval > 0,
    );
  } else {
    measurement = ServiceUsage(
      unit: ServiceUnit.kilometres,
      used: latestEntry?.mileageAtServiceKm != null
          ? (currentMileageKm - latestEntry!.mileageAtServiceKm!)
              .clamp(0, double.infinity)
          : currentMileageKm,
      interval: component.interval,
      available: mileageAvailable &&
          component.interval > 0 &&
          latestEntry?.mileageAtServiceKm != null,
    );
  }
  return AnnotatedService(
      component: component,
      measurement: measurement,
      lastServicedAt: latestEntry?.date);
}
