import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';

class ServiceComponentCard extends StatelessWidget {
  final ServiceComponent component;
  final double currentMileageKm;
  final ServiceEntry? latestEntry;
  final VoidCallback? onTap;

  const ServiceComponentCard({
    super.key,
    required this.component,
    required this.currentMileageKm,
    this.latestEntry,
    this.onTap,
  });

  static const _greenColor = Color(0xFF4A9E6E);
  static const _amberColor = Color(0xFFE8A44A);
  static const _redColor = Color(0xFFE05545);
  static const _unknownColor = Color(0xFF6B7280); // neutral grey

  /// True when there is a service entry but mileage was not recorded.
  bool get _mileageUnknown =>
      latestEntry != null && latestEntry!.mileageAtServiceKm == null;

  double get kmSinceService {
    if (latestEntry?.mileageAtServiceKm != null) {
      return (currentMileageKm - latestEntry!.mileageAtServiceKm!)
          .clamp(0.0, double.infinity);
    }
    return currentMileageKm;
  }

  double get progress {
    if (_mileageUnknown) return 0.0;
    if (component.serviceIntervalKm <= 0) return 0.0;
    return kmSinceService / component.serviceIntervalKm;
  }

  Color get statusColor {
    if (_mileageUnknown) return _unknownColor;
    if (progress >= 0.9) return _redColor;
    if (progress >= 0.7) return _amberColor;
    return _greenColor;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    // ── Unknown-mileage layout ─────────────────────────────────────────────
    if (_mileageUnknown) {
      final dateText = DateFormat('MMM d, yyyy').format(latestEntry!.date);
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.6) ??
                Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                  color: _unknownColor.withValues(alpha: 0.5), width: 3),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
            children: [
              Icon(
                _iconForComponent(component.type.icon),
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  component.type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'no mileage data',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // ── Normal km-based layout ─────────────────────────────────────────────
    final kmText = formatter.format(kmSinceService.round());
    final intervalText = 'of ${formatter.format(component.serviceIntervalKm)} km';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.6) ??
              Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: statusColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _iconForComponent(component.type.icon),
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          component.type.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$kmText km',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (progress >= 0.9) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _redColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DUE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _redColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (component.name != component.type.label)
                  Flexible(
                    child: Text(
                      component.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  intervalText,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForComponent(String icon) {
    switch (icon) {
      case 'link':
        return Icons.link;
      case 'brake':
        return Icons.pan_tool;
      case 'tire':
        return Icons.circle_outlined;
      case 'fork':
        return Icons.swap_vert;
      case 'shock':
        return Icons.compress;
      case 'bearing':
        return Icons.settings;
      default:
        return Icons.build;
    }
  }
}
