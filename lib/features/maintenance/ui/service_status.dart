import '../models/service_schedule.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

export '../models/service_schedule.dart';

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
