import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:flutter/material.dart';

enum ServiceStatus { red, amber, green, unknown }

extension ServiceStatusColor on ServiceStatus {
  Color color(AppPalette p) {
    switch (this) {
      case ServiceStatus.red: return p.red;
      case ServiceStatus.amber: return p.amber;
      case ServiceStatus.green: return p.green;
      case ServiceStatus.unknown: return p.inkDim;
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
}) {
  final mileageUnknown =
      latestEntry != null && latestEntry.mileageAtServiceKm == null;
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

IconData iconForComponent(String icon) {
  switch (icon) {
    case 'link': return Icons.link_rounded;
    case 'brake': return Icons.pan_tool_rounded;
    case 'tire': return Icons.circle_outlined;
    case 'fork': return Icons.swap_vert_rounded;
    case 'shock': return Icons.compress_rounded;
    case 'bearing': return Icons.settings_rounded;
    default: return Icons.build_rounded;
  }
}

class ForecastStrip extends StatelessWidget {
  final AnnotatedService next;
  const ForecastStrip({super.key, required this.next});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = next.status.color(p);
    final remaining = next.remainingKm.round();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT SERVICE',
                  style: AppTextStyles.inter(
                    size: 9, weight: FontWeight.w700,
                    color: p.inkDim, letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  next.component.type.label,
                  style: AppTextStyles.inter(
                    size: 13, weight: FontWeight.w600, color: p.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    remaining == 0 ? 'now' : '$remaining',
                    style: AppTextStyles.mono(
                      size: 16, weight: FontWeight.w700,
                      color: color, height: 1,
                    ),
                  ),
                  if (remaining > 0) ...[
                    const SizedBox(width: 2),
                    Text(
                      'km',
                      style: AppTextStyles.inter(
                        size: 9, weight: FontWeight.w600,
                        color: p.inkDim,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                remaining == 0 ? 'OVERDUE' : 'REMAINING',
                style: AppTextStyles.inter(
                  size: 8.5, weight: FontWeight.w600,
                  color: p.inkDim, letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ServiceStatsRow extends StatelessWidget {
  final int dueCount;
  final int soonCount;
  final int healthyCount;
  const ServiceStatsRow({
    super.key,
    required this.dueCount,
    required this.soonCount,
    required this.healthyCount,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          Expanded(child: _StatChip(count: dueCount, label: 'Due', color: p.red)),
          const SizedBox(width: 6),
          Expanded(child: _StatChip(count: soonCount, label: 'Soon', color: p.amber)),
          const SizedBox(width: 6),
          Expanded(child: _StatChip(count: healthyCount, label: 'Healthy', color: p.green)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppTextStyles.mono(
                  size: 15, weight: FontWeight.w700, color: p.ink, height: 1.1,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.inter(
                  size: 8.5, weight: FontWeight.w700,
                  color: p.inkDim, letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusGroupHeader extends StatelessWidget {
  final ServiceStatus status;
  final String label;
  final int count;
  const StatusGroupHeader({
    super.key,
    required this.status,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = status.color(p);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.inter(
              size: 10, weight: FontWeight.w700,
              color: p.ink, letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: AppTextStyles.inter(
              size: 10, weight: FontWeight.w700, color: p.inkDim,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: p.border)),
        ],
      ),
    );
  }
}
