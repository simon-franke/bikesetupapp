import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'service_status.dart';

/// Presents the loaded schedule in urgency order.
class ServiceSchedule extends StatelessWidget {
  final VoidCallback? onAdd;
  final List<AnnotatedService> services;
  final Widget Function(AnnotatedService) cardBuilder;

  const ServiceSchedule(
      {super.key,
      required this.services,
      required this.cardBuilder,
      this.onAdd});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (services.isEmpty) {
      return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: p.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Keep your bike ready',
                        style: AppTextStyles.heading.copyWith(color: p.ink)),
                    const SizedBox(height: 12),
                    Text(
                        'Track service intervals and keep a history of the work you do.',
                        style: AppTextStyles.body.copyWith(color: p.inkMuted)),
                    const SizedBox(height: 24),
                    AppAddButton(label: 'Add component', onPressed: onAdd),
                  ])));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
          child: Text('Service schedule',
              style: AppTextStyles.label.copyWith(color: p.ink))),
      ..._group(context, {ServiceStatus.red}, 'Needs attention'),
      ..._group(
          context, {ServiceStatus.amber, ServiceStatus.green}, 'Upcoming'),
      ..._group(context, {ServiceStatus.unknown}, 'Needs a starting point'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppAddButton(label: 'Add component', onPressed: onAdd),
      ),
    ]);
  }

  List<Widget> _group(
      BuildContext context, Set<ServiceStatus> statuses, String label) {
    final entries = services.where((s) => statuses.contains(s.status)).toList()
      ..sort((a, b) {
        final remaining = b.progress.compareTo(a.progress);
        if (remaining != 0) return remaining;
        final overdue = b.usage.compareTo(a.usage);
        if (overdue != 0) return overdue;
        return a.component.name
            .toLowerCase()
            .compareTo(b.component.name.toLowerCase());
      });
    if (entries.isEmpty) return [];

    return [
      Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Text(label,
            style:
                AppTextStyles.label.copyWith(color: context.palette.inkMuted)),
      ),
      Column(children: entries.map(cardBuilder).toList()),
    ];
  }
}
