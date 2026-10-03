import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiceComponentCard extends StatelessWidget {
  final ServiceComponent component;
  final EdgeInsetsGeometry margin;
  final double currentMileageKm;
  final bool mileageAvailable;
  final ServiceEntry? latestEntry;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onDefer;

  const ServiceComponentCard({
    super.key,
    required this.component,
    this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    required this.currentMileageKm,
    this.mileageAvailable = true,
    this.latestEntry,
    this.onTap,
    this.onLog,
    this.onDefer,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = annotateService(
      component: component,
      currentMileageKm: currentMileageKm,
      latestEntry: latestEntry,
      mileageAvailable: mileageAvailable,
    );
    final color = s.mileageUnknown ? p.inkMuted : s.status.color(p);
    final format = NumberFormat('#,###');
    final lastService = s.lastServicedAt == null
        ? 'No service recorded'
        : 'Last serviced ${DateFormat.yMMMd().format(s.lastServicedAt!)}';

    return Padding(
      padding: margin,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(iconForComponent(component.type.icon),
                          size: 22, color: p.inkMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(component.type.label,
                                style: Theme.of(context).textTheme.titleMedium),
                            if (component.name.trim().isNotEmpty &&
                                component.name.trim() != component.type.label)
                              Text(component.name,
                                  style: TextStyle(
                                      fontSize: 13, color: p.inkMuted)),
                          ],
                        ),
                      ),
                      if (onTap != null)
                        Icon(Icons.chevron_right, color: p.inkMuted, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                serviceDistanceLabel(s),
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                s.mileageUnknown
                    ? 'Service interval: ${format.format(component.serviceIntervalKm)} km'
                    : '${format.format(s.kmSinceService.round())} of ${format.format(component.serviceIntervalKm)} km since service',
                style: TextStyle(fontSize: 13, color: p.inkMuted),
              ),
              if (!s.mileageUnknown) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: s.progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: p.surface2,
                    valueColor: AlwaysStoppedAnimation(color),
                    semanticsLabel:
                        '${component.type.label} service interval used',
                  ),
                ),
              ],
              if (s.lastServicedAt != null) ...[
                const SizedBox(height: 10),
                Text(lastService,
                    style: TextStyle(fontSize: 12, color: p.inkMuted)),
              ],
              if (onLog != null || onDefer != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (onLog != null)
                      FilledButton.icon(
                        onPressed: onLog,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Log service'),
                      ),
                    if (s.status == ServiceStatus.red && onDefer != null)
                      TextButton(
                        onPressed: onDefer,
                        style: TextButton.styleFrom(
                          foregroundColor: p.inkMuted,
                          minimumSize: const Size(0, 44),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('Defer service'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
