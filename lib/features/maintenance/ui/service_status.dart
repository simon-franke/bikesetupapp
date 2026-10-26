import 'package:flutter/cupertino.dart';
import '../models/service_schedule.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
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
  if (service.component.interval <= 0) return 'Set a service interval';
  if (service.lastServicedAt == null) return 'No service recorded';
  if (service.mileageUnknown) {
    return service.component.usesHours
        ? 'Ride log needed to estimate service'
        : 'Mileage needed to estimate service';
  }
  final format = NumberFormat('#,###');
  final overdue = service.usage - service.component.interval;
  if (overdue > 0) {
    return '${service.component.usesHours ? overdue.toStringAsFixed(1) : format.format(overdue.round())} ${service.component.unitLabel} overdue';
  }
  if (service.remaining == 0) return 'Service due now';
  return 'Service in ${service.component.usesHours ? service.remaining.toStringAsFixed(1) : format.format(service.remaining.round())} ${service.component.unitLabel}';
}

IconData iconForComponent(String icon) {
  switch (icon) {
    case 'link':
      return CupertinoIcons.link;
    case 'brake':
      return CupertinoIcons.hand_raised;
    case 'tire':
      return CupertinoIcons.circle;
    case 'fork':
      return CupertinoIcons.arrow_up_arrow_down;
    case 'shock':
      return CupertinoIcons.arrow_down_right_arrow_up_left;
    case 'bearing':
      return CupertinoIcons.gear_alt;
    default:
      return CupertinoIcons.wrench;
  }
}
