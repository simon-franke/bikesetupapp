import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'service_component_icon.dart';
import 'package:flutter/cupertino.dart';
import '../../rides/models/ride.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_status.dart';
import 'package:flutter/material.dart';

class ServiceComponentCard extends StatelessWidget {
  final List<Ride>? rides;
  final ServiceComponent component;
  final EdgeInsetsGeometry margin;
  final double currentMileageKm;
  final bool mileageAvailable;
  final ServiceEntry? latestEntry;
  final VoidCallback? onTap;

  const ServiceComponentCard({
    super.key,
    required this.component,
    this.rides,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    required this.currentMileageKm,
    this.mileageAvailable = true,
    this.latestEntry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = annotateService(
      component: component,
      rides: rides,
      currentMileageKm: currentMileageKm,
      latestEntry: latestEntry,
      mileageAvailable: mileageAvailable,
    );
    final color = s.usageUnknown ? p.inkMuted : s.status.color(p);
    return Padding(
        padding: margin,
        child: Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: AppHaptics.wrap(onTap),
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          ServiceComponentIcon(
                              type: component.type,
                              customIcon: component.customIcon,
                              size: 22,
                              color: p.inkMuted),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  component.name.trim().isEmpty
                                      ? component.type.label
                                      : component.name,
                                  style: AppTextStyles.inter(
                                      size: 16,
                                      weight: FontWeight.w600,
                                      color: p.ink))),
                          if (onTap != null) ...[
                            const SizedBox(width: 12),
                            Icon(CupertinoIcons.chevron_right,
                                size: 16, color: p.inkMuted)
                          ],
                        ]),
                        const SizedBox(height: 12),
                        Text(serviceDistanceLabel(s),
                            style: AppTextStyles.inter(size: 16, color: color)),
                        if (!s.usageUnknown) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                              value: s.progress.clamp(0, 1),
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(5),
                              color: s.status == ServiceStatus.green
                                  ? p.accent
                                  : color,
                              backgroundColor: p.surface2,
                              semanticsLabel:
                                  '${component.name} service interval used'),
                        ],
                      ]))),
        ));
  }
}
