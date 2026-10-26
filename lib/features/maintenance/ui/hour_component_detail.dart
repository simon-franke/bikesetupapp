import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../../rides/models/ride.dart';
import '../models/service_component.dart';
import '../models/service_entry.dart';
import 'service_component_card.dart';
import 'hour_service_sheet.dart';

class HourComponentDetail extends StatefulWidget {
  const HourComponentDetail(
      {super.key, required this.uid, required this.component});
  final String uid;
  final ServiceComponent component;
  @override
  State<HourComponentDetail> createState() => _HourComponentDetailState();
}

class _HourComponentDetailState extends State<HourComponentDetail> {
  late final db = AppDependencies.of(context).forUser(widget.uid);
  late Stream<List<Ride>> rides = db.rides.watch(widget.component.bikeId);
  late Stream<List<ServiceEntry>> entries =
      db.maintenance.getEntriesForComponent(widget.component.id);
  late ServiceComponent component = widget.component;
  Future<void> editInterval() async {
    final interval = await showAppSheet<double>(
        context: context,
        builder: (_) =>
            HourIntervalForm(initial: component.serviceIntervalHours!));
    if (interval == null || !mounted) return;
    if (await presentCommand(
            context,
            () => db.maintenance.updateComponent(component.id,
                serviceIntervalHours: interval)) &&
        mounted) {
      setState(() => component = ServiceComponent(
          id: component.id,
          bikeId: component.bikeId,
          type: component.type,
          name: component.name,
          serviceIntervalKm: component.serviceIntervalKm,
          createdAt: component.createdAt,
          serviceIntervalHours: interval,
          includeIndoorRides: component.includeIndoorRides));
    }
  }

  Future<bool> confirm(String title, String text) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) =>
              AlertDialog(title: Text(title), content: Text(text), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'))
              ])) ??
      false;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(component.name), actions: [
        IconButton(
            tooltip: 'Edit service interval',
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: editInterval),
        IconButton(
            tooltip: 'Delete component',
            icon: const Icon(CupertinoIcons.trash),
            onPressed: () async {
              if (!await confirm('Delete component?',
                      'This removes the component and its service history. Your ride log is kept.') ||
                  !context.mounted) {
                return;
              }
              if (await presentCommand(context,
                      () => db.maintenance.deleteComponent(component.id)) &&
                  context.mounted) {
                Navigator.pop(context);
              }
            })
      ]),
      body: StreamBuilder<List<ServiceEntry>>(
          stream: entries,
          builder: (context, history) => StreamBuilder<List<Ride>>(
              stream: rides,
              builder: (context, rideSnapshot) {
                if (history.hasError || rideSnapshot.hasError) {
                  return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Could not load service data.'),
                    TextButton(
                        onPressed: () => setState(() {
                              rides = db.rides.watch(component.bikeId);
                              entries = db.maintenance
                                  .getEntriesForComponent(component.id);
                            }),
                        child: const Text('Retry'))
                  ]));
                }
                if (!history.hasData || !rideSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      ServiceComponentCard(
                          component: component,
                          currentMileageKm: 0,
                          rides: rideSnapshot.data,
                          latestEntry: history.data!.firstOrNull),
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(component.includeIndoorRides
                              ? 'Indoor and outdoor rides count.'
                              : 'Outdoor rides count. Indoor rides are excluded.')),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Service history',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600))),
                      for (final entry in history.data!)
                        ListTile(
                            title: Text(DateFormat.yMMMd()
                                .add_Hm()
                                .format(entry.date.toLocal())),
                            subtitle: Text(
                                '${entry.note ?? 'Service logged'}${(entry.initialRideHours ?? 0) > 0 ? '\n${entry.initialRideHours} additional hours already used' : ''}'),
                            trailing: IconButton(
                                tooltip: 'Delete service entry',
                                icon: const Icon(CupertinoIcons.trash),
                                onPressed: () async {
                                  if (!await confirm('Delete service entry?',
                                          'Service progress will be recalculated using the preceding service.') ||
                                      !context.mounted) {
                                    return;
                                  }
                                  await presentCommand(
                                      context,
                                      () => db.maintenance.deleteServiceEntry(
                                          component.id, entry.id));
                                })),
                    ]);
              })),
      floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(CupertinoIcons.check_mark),
          label: const Text('Log service'),
          onPressed: () => showAppSheet<void>(
              context: context,
              builder: (_) =>
                  HourServiceSheet(uid: widget.uid, component: component))));
}

class HourIntervalForm extends StatefulWidget {
  const HourIntervalForm({super.key, required this.initial});
  final double initial;
  @override
  State<HourIntervalForm> createState() => _HourIntervalFormState();
}

class _HourIntervalFormState extends State<HourIntervalForm> {
  late final text = TextEditingController(text: widget.initial.toString());
  String? error;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Service interval',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            AppTextField(
                controller: text,
                hint: 'Ride hours',
                suffix: 'h',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                errorText: error),
            const SizedBox(height: 20),
            AppActionButton(
                label: 'Save',
                onPressed: () {
                  final value = double.tryParse(text.text);
                  if (value == null || !value.isFinite || value <= 0) {
                    setState(() => error = 'Enter a positive number of hours.');
                    return;
                  }
                  Navigator.pop(context, value);
                }),
          ]));
}
