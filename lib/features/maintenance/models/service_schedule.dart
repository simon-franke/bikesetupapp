import '../../rides/models/ride.dart';
import 'service_component.dart';
import 'service_entry.dart';

enum ServiceStatus { red, amber, green, unknown }

class AnnotatedService {
  final ServiceComponent component;
  final double kmSinceService;
  final double remainingKm;
  final double progress;
  final ServiceStatus status;
  final DateTime? lastServicedAt;
  final bool mileageUnknown;
  final double? hoursSinceService;
  double get usage => hoursSinceService ?? kmSinceService;
  double get remaining =>
      (component.interval - usage).clamp(0, double.infinity);

  const AnnotatedService({
    required this.component,
    required this.kmSinceService,
    required this.remainingKm,
    required this.progress,
    required this.status,
    required this.lastServicedAt,
    required this.mileageUnknown,
    this.hoursSinceService,
  });
}

AnnotatedService annotateService({
  required ServiceComponent component,
  required double currentMileageKm,
  required ServiceEntry? latestEntry,
  bool mileageAvailable = true,
  List<Ride>? rides,
}) {
  final mileageUnknown = component.usesHours
      ? rides == null || latestEntry == null || component.interval <= 0
      : !mileageAvailable ||
          component.serviceIntervalKm <= 0 ||
          latestEntry == null ||
          latestEntry.mileageAtServiceKm == null;
  final kmSince = (latestEntry?.mileageAtServiceKm != null)
      ? (currentMileageKm - latestEntry!.mileageAtServiceKm!)
          .clamp(0.0, double.infinity)
      : currentMileageKm;
  final hourUsage = component.usesHours && latestEntry != null && rides != null
      ? (latestEntry.initialRideHours ?? 0) +
          hoursSince(rides, latestEntry.date,
              includeIndoor: component.includeIndoorRides)
      : null;
  final progress = !mileageUnknown && component.interval > 0
      ? (hourUsage ?? kmSince) / component.interval
      : 0.0;
  final remaining =
      (component.serviceIntervalKm - kmSince).clamp(0.0, double.infinity);
  ServiceStatus status;
  if (mileageUnknown) {
    status = ServiceStatus.unknown;
  } else if (progress >= 0.9) {
    status = ServiceStatus.red;
  } else if (progress >= 0.7) {
    status = ServiceStatus.amber;
  } else {
    status = ServiceStatus.green;
  }
  return AnnotatedService(
    component: component,
    hoursSinceService: hourUsage,
    kmSinceService: kmSince,
    remainingKm: remaining,
    progress: progress,
    status: status,
    lastServicedAt: latestEntry?.date,
    mileageUnknown: mileageUnknown,
  );
}
