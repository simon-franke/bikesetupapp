import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import '../models/service_component.dart';
import '../models/service_entry.dart';

class ServiceHistoryEntry extends StatelessWidget {
  const ServiceHistoryEntry(
      {super.key,
      required this.entry,
      required this.component,
      required this.onDelete});

  final ServiceEntry entry;
  final ServiceComponent component;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          component.usesHours
                              ? DateFormat.yMMMd()
                                  .add_Hm()
                                  .format(entry.date.toLocal())
                              : DateFormat.yMMMd().format(entry.date.toLocal()),
                          style: AppTextStyles.label.copyWith(color: p.ink)),
                      if (entry.mileageAtServiceKm != null &&
                          !component.usesHours) ...[
                        const SizedBox(height: 6),
                        Text(
                            '${NumberFormat('#,###').format(entry.mileageAtServiceKm!.round())} km',
                            style:
                                AppTextStyles.body.copyWith(color: p.inkMuted)),
                      ],
                      if ((entry.initialDistanceKm ?? 0) > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                            '${NumberFormat('#,###.#').format(entry.initialDistanceKm)} km already used',
                            style:
                                AppTextStyles.body.copyWith(color: p.inkMuted)),
                      ],
                      if ((entry.initialRideHours ?? 0) > 0) ...[
                        const SizedBox(height: 6),
                        Text('${entry.initialRideHours} hours already used',
                            style:
                                AppTextStyles.body.copyWith(color: p.inkMuted)),
                      ],
                      if (entry.note?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text(entry.note!,
                            style:
                                AppTextStyles.body.copyWith(color: p.inkMuted)),
                      ],
                    ]))),
        Builder(
            builder: (anchor) => IconButton(
                tooltip: 'Service entry options',
                icon: const Icon(CupertinoIcons.ellipsis),
                onPressed: () async {
                  final action = await showAppOptionsSheet(
                      context: anchor,
                      title: 'Service entry',
                      entries: const [
                        AppSheetOption(
                            value: 'delete',
                            label: 'Delete entry',
                            icon: CupertinoIcons.trash,
                            destructive: true)
                      ]);
                  if (action == 'delete' && context.mounted) {
                    await onDelete();
                  }
                })),
      ]),
      Divider(height: 1, color: p.border),
    ]);
  }
}
