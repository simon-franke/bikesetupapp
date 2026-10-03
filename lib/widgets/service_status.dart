import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ServiceStatus { red, amber, green, unknown }

extension ServiceStatusColor on ServiceStatus {
  Color color(AppPalette p) {
    switch (this) {
      case ServiceStatus.red:
        return p.red;
      case ServiceStatus.amber:
        return p.amber;
      case ServiceStatus.green:
        return p.green;
      case ServiceStatus.unknown:
        return p.inkDim;
    }
  }
}

class AnnotatedService {
  final ServiceComponent component;
  final double kmSinceService;
  final double remainingKm;
  final double progress;
  final ServiceStatus status;
  final DateTime? lastServicedAt;
  final bool mileageUnknown;

  const AnnotatedService({
    required this.component,
    required this.kmSinceService,
    required this.remainingKm,
    required this.progress,
    required this.status,
    required this.lastServicedAt,
    required this.mileageUnknown,
  });
}

AnnotatedService annotateService({
  required ServiceComponent component,
  required double currentMileageKm,
  required ServiceEntry? latestEntry,
  bool mileageAvailable = true,
}) {
  final mileageUnknown = !mileageAvailable ||
      component.serviceIntervalKm <= 0 ||
      latestEntry == null ||
      latestEntry.mileageAtServiceKm == null;
  final kmSince = (latestEntry?.mileageAtServiceKm != null)
      ? (currentMileageKm - latestEntry!.mileageAtServiceKm!)
          .clamp(0.0, double.infinity)
      : currentMileageKm;
  final progress = component.serviceIntervalKm > 0
      ? kmSince / component.serviceIntervalKm
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
    kmSinceService: kmSince,
    remainingKm: remaining,
    progress: progress,
    status: status,
    lastServicedAt: latestEntry?.date,
    mileageUnknown: mileageUnknown,
  );
}

String serviceDistanceLabel(AnnotatedService service) {
  if (service.component.serviceIntervalKm <= 0) return 'Set a service interval';
  if (service.lastServicedAt == null) return 'No service recorded';
  if (service.mileageUnknown) return 'Mileage needed to estimate service';
  final format = NumberFormat('#,###');
  final overdue = service.kmSinceService - service.component.serviceIntervalKm;
  if (overdue > 0) return '${format.format(overdue.round())} km overdue';
  if (service.remainingKm == 0) return 'Service due now';
  return 'Service in ${format.format(service.remainingKm.round())} km';
}

IconData iconForComponent(String icon) {
  switch (icon) {
    case 'link':
      return Icons.link_rounded;
    case 'brake':
      return Icons.pan_tool_rounded;
    case 'tire':
      return Icons.circle_outlined;
    case 'fork':
      return Icons.swap_vert_rounded;
    case 'shock':
      return Icons.compress_rounded;
    case 'bearing':
      return Icons.settings_rounded;
    default:
      return Icons.build_rounded;
  }
}
