import 'service_component_icon.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/common/ui/delete_confirmation_sheet.dart';
import '../../rides/models/ride.dart';
import '../models/service_component.dart';
import '../models/service_entry.dart';
import 'service_status.dart';
import 'service_controls.dart';
import 'log_service_sheet.dart';
import 'defer_service_sheet.dart';

class ComponentDetailPage extends StatefulWidget {
  const ComponentDetailPage(
      {super.key,
      required this.user,
      required this.component,
      required this.currentMileageKm,
      this.mileageAvailable = true,
      this.stravaGearId});
  final User user;
  final ServiceComponent component;
  final double currentMileageKm;
  final bool mileageAvailable;
  final String? stravaGearId;
  @override
  State<ComponentDetailPage> createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  late final db = AppDependencies.of(context).forUser(widget.user.uid);
  late ServiceComponent component = widget.component;
  late Stream<List<ServiceEntry>> entries =
      db.maintenance.getEntriesForComponent(component.id);
  late Stream<List<Ride>> rides = db.rides.watch(component.bikeId);

  Future<void> editInterval() async {
    final value = await showAppSheet<double>(
        context: context,
        builder: (_) => ServiceIntervalSheet(
            initial: component.interval, hours: component.usesHours));
    if (value == null || !mounted || value == component.interval) return;
    final saved = await presentCommand(
        context,
        () => db.maintenance.updateComponent(component.id,
            serviceIntervalKm: component.usesHours ? null : value.toInt(),
            serviceIntervalHours: component.usesHours ? value : null));
    if (!mounted || !saved) return;
    setState(() => component = ServiceComponent(
        id: component.id,
        bikeId: component.bikeId,
        type: component.type,
        name: component.name,
        customIcon: component.customIcon,
        createdAt: component.createdAt,
        serviceIntervalKm:
            component.usesHours ? component.serviceIntervalKm : value.toInt(),
        serviceIntervalHours: component.usesHours ? value : null,
        includeIndoorRides: component.includeIndoorRides));
  }

  Future<bool> confirmDelete(String title, String message) =>
      showDeleteConfirmationSheet(context, title: title, message: message);

  Future<void> deleteComponent() async {
    if (!await confirmDelete('Delete component?',
            'This permanently removes ${component.name} and its service history.') ||
        !mounted) {
      return;
    }
    if (await presentCommand(
            context, () => db.maintenance.deleteComponent(component.id)) &&
        mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> deleteEntry(ServiceEntry entry) async {
    if (!await confirmDelete('Delete service entry?',
            'Service progress will be recalculated using the preceding entry.') ||
        !mounted) {
      return;
    }
    await presentCommand(context,
        () => db.maintenance.deleteServiceEntry(component.id, entry.id));
  }

  Future<void> options(BuildContext anchor) async {
    final action = await showAppOptionsSheet(
        context: anchor,
        title: component.name,
        entries: const [
          AppSheetOption(
              value: 'interval',
              label: 'Edit interval',
              icon: CupertinoIcons.slider_horizontal_3),
          AppSheetOption(
              value: 'delete',
              label: 'Delete component',
              icon: CupertinoIcons.trash,
              destructive: true),
        ]);
    if (!mounted) {
      return;
    }
    if (action == 'interval') await editInterval();
    if (action == 'delete') await deleteComponent();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(component.name), actions: [
          Builder(
              builder: (anchor) => IconButton(
                  tooltip: 'Component options',
                  icon: const Icon(CupertinoIcons.ellipsis),
                  onPressed: () => options(anchor))),
        ]),
        body: StreamBuilder<List<ServiceEntry>>(
            stream: entries,
            builder: (context, history) {
              return StreamBuilder<List<Ride>>(
                  stream: rides,
                  builder: (_, rideSnapshot) => content(history, rideSnapshot));
            }),
      );

  void _logService() => showLogServiceSheet(
      context: context,
      userID: widget.user.uid,
      component: component,
      currentMileageKm: widget.currentMileageKm,
      stravaGearId: widget.mileageAvailable ? widget.stravaGearId : null);

  Widget content(AsyncSnapshot<List<ServiceEntry>> history,
      AsyncSnapshot<List<Ride>>? rideSnapshot) {
    if (history.hasError || (rideSnapshot?.hasError ?? false)) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Could not load service data.'),
        TextButton(
            onPressed: () => setState(() {
                  entries = db.maintenance.getEntriesForComponent(component.id);
                  rides = db.rides.watch(component.bikeId);
                }),
            child: const Text('Try again')),
      ]));
    }
    if (!history.hasData || !(rideSnapshot?.hasData ?? false)) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final p = context.palette;
    final items = history.data!;
    final service = annotateService(
        component: component,
        currentMileageKm: widget.currentMileageKm,
        latestEntry: items.firstOrNull,
        mileageAvailable: widget.mileageAvailable,
        rides: rideSnapshot?.data);
    final color = service.status == ServiceStatus.green
        ? p.accentText
        : service.status.color(p);
    String amount(double value) => component.usesHours
        ? value.toStringAsFixed(1)
        : NumberFormat('#,###').format(value.round());
    return ListView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: p.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceComponentIcon(
                      type: component.type,
                      customIcon: component.customIcon,
                      color: p.accentText,
                      size: 44),
                  const SizedBox(height: 24),
                  Text('Start your service history',
                      style: AppTextStyles.inter(
                          size: 22, weight: FontWeight.w600, color: p.ink)),
                  const SizedBox(height: 12),
                  Text('Log the last service to see when the next one is due.',
                      style: AppTextStyles.inter(size: 14, color: p.inkMuted)),
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: AppActionButton(
                          label: 'Log service', onPressed: _logService)),
                ],
              ),
            )
          else
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: p.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(serviceDistanceLabel(service),
                          style: AppTextStyles.inter(
                              size: 22, weight: FontWeight.w600, color: color)),
                      if (!service.usageUnknown) ...[
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                            value: service.progress.clamp(0, 1),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                            color: service.status == ServiceStatus.green
                                ? p.accent
                                : color,
                            backgroundColor: p.surface2),
                        const SizedBox(height: 12),
                        Text(
                            '${amount(service.usage)} of ${amount(component.interval)} ${component.unitLabel} used',
                            style: AppTextStyles.inter(
                                size: 14, color: p.inkMuted)),
                      ],
                      if (!component.usesHours &&
                          widget.mileageAvailable &&
                          service.status == ServiceStatus.red) ...[
                        const SizedBox(height: 12),
                        TextButton(
                            onPressed: () => showDeferServiceSheet(
                                context: context,
                                userID: widget.user.uid,
                                component: component,
                                currentMileageKm: widget.currentMileageKm),
                            child: const Text('Defer service')),
                      ],
                    ])),
          const SizedBox(height: 16),
          AppValueButton(
              label: 'Service interval',
              value:
                  'Every ${amount(component.interval)} ${component.unitLabel}',
              onTap: editInterval),
          if (component.usesHours)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                    component.includeIndoorRides
                        ? 'Indoor and outdoor rides count.'
                        : 'Outdoor rides count.',
                    style: AppTextStyles.inter(size: 14, color: p.inkMuted))),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 20),
            AppActionButton(label: 'Log service', onPressed: _logService),
            const SizedBox(height: 32),
            Text('Service history',
                style: AppTextStyles.inter(
                    size: 18, weight: FontWeight.w600, color: p.ink)),
            const SizedBox(height: 16),
          ],
          for (final entry in items) ...[
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
                                    : DateFormat.yMMMd()
                                        .format(entry.date.toLocal()),
                                style: AppTextStyles.inter(
                                    size: 16,
                                    weight: FontWeight.w600,
                                    color: p.ink)),
                            if (entry.mileageAtServiceKm != null &&
                                !component.usesHours) ...[
                              const SizedBox(height: 6),
                              Text(
                                  '${NumberFormat('#,###').format(entry.mileageAtServiceKm!.round())} km',
                                  style: AppTextStyles.inter(
                                      size: 14, color: p.inkMuted)),
                            ],
                            if ((entry.initialDistanceKm ?? 0) > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                  '${NumberFormat('#,###.#').format(entry.initialDistanceKm)} km already used',
                                  style: TextStyle(
                                      color: p.inkMuted, fontSize: 14)),
                            ],
                            if ((entry.initialRideHours ?? 0) > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                  '${entry.initialRideHours} hours already used',
                                  style: AppTextStyles.inter(
                                      size: 14, color: p.inkMuted)),
                            ],
                            if (entry.note?.trim().isNotEmpty ?? false) ...[
                              const SizedBox(height: 6),
                              Text(entry.note!,
                                  style: AppTextStyles.inter(
                                      size: 16, color: p.inkMuted)),
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
                        if (action == 'delete' && mounted) {
                          await deleteEntry(entry);
                        }
                      })),
            ]),
            Divider(height: 1, color: p.border),
          ],
        ]);
  }
}
