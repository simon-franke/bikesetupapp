import 'fit_ride_import.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:bikesetupapp/common/ui/delete_confirmation_sheet.dart';
import 'bike_mileage_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/rides_controller.dart';
import '../models/ride.dart';

import 'manual_ride_form.dart';

class RideLogPage extends StatefulWidget {
  const RideLogPage(
      {super.key,
      required this.uid,
      required this.bikeId,
      required this.bikeName});

  final String uid, bikeId, bikeName;

  @override
  State<RideLogPage> createState() => _RideLogPageState();
}

class _RideLogPageState extends State<RideLogPage> {
  late final RidesController controller =
      AppDependencies.of(context).forUser(widget.uid).rides;
  late Stream<List<Ride>> stream = controller.watch(widget.bikeId);
  bool importing = false;
  String? message;

  Future<void> importFit() async {
    setState(() {
      importing = true;
      message = null;
    });
    try {
      final result = await importFitRides(context,
          controller: controller,
          bikeId: widget.bikeId,
          bikeName: widget.bikeName);
      if (mounted) setState(() => message = result);
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: buildDetailAppBar(context, title: 'Ride activity'),
      body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              ListView(padding: const EdgeInsets.all(20), children: [
                Text(widget.bikeName,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                BikeMileagePanel(
                    key: ValueKey(widget.bikeId),
                    uid: widget.uid,
                    bikeId: widget.bikeId),
                const SizedBox(height: 20),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  AppActionButton(
                      label: 'Log ride',
                      icon: CupertinoIcons.plus,
                      onPressed: importing || controller.isBusy
                          ? null
                          : () => showAppSheet<void>(
                              context: context,
                              builder: (_) => ManualRideForm(
                                  controller: controller,
                                  bikeId: widget.bikeId,
                                  bikeName: widget.bikeName))),
                  AppActionButton(
                      label: importing ? 'Reading FIT…' : 'Import FIT',
                      icon: CupertinoIcons.square_arrow_down,
                      outlined: true,
                      onPressed:
                          importing || controller.isBusy ? null : importFit),
                ]),
                if (message != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(message!, semanticsLabel: message)),
                const SizedBox(height: 20),
                StreamBuilder<List<Ride>>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Column(children: [
                          const Text('Could not load rides.'),
                          TextButton(
                              onPressed: () => setState(() =>
                                  stream = controller.watch(widget.bikeId)),
                              child: const Text('Retry'))
                        ]);
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: AppLoadingState());
                      }

                      final rides = snapshot.data!;

                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (rides.isNotEmpty)
                              Text(
                                  [
                                    '${rides.length} ${rides.length == 1 ? 'ride' : 'rides'}',
                                    if (rides.any((r) => r.distanceKm != null))
                                      '${rides.fold<double>(0, (sum, r) => sum + (r.distanceKm ?? 0)).toStringAsFixed(1)} km',
                                    if (rides.any((r) => r.durationSeconds > 0))
                                      '${rides.fold<double>(0, (sum, r) => sum + r.hours).toStringAsFixed(1)} h',
                                  ].join('   '),
                                  style: AppTextStyles.body.copyWith(
                                      color: context.palette.inkMuted)),
                            const SizedBox(height: 12),
                            if (rides.isEmpty)
                              Text('Add rides to track service intervals.',
                                  style: AppTextStyles.body.copyWith(
                                      color: context.palette.inkMuted)),
                            for (final ride in rides)
                              Card(
                                  child: ListTile(
                                      title: Text(ride.name.isEmpty
                                          ? 'Ride'
                                          : ride.name),
                                      subtitle: Text(
                                          '${DateFormat.yMMMd().add_Hm().format(ride.startedAt.toLocal())}\n${[
                                        if (ride.distanceKm != null)
                                          '${ride.distanceKm!.toStringAsFixed(1)} km',
                                        if (ride.durationSeconds > 0)
                                          '${ride.hours.toStringAsFixed(2)} hours'
                                      ].join(' · ')}, ${ride.indoor ? 'Indoor' : 'Outdoor'}, ${ride.source == 'fit' ? 'FIT import' : 'Manual'}'),
                                      trailing: IconButton(
                                          tooltip: 'Delete ride',
                                          icon:
                                              const Icon(CupertinoIcons.trash),
                                          onPressed: controller.isBusy
                                              ? null
                                              : () async {
                                                  final remove =
                                                      await showDeleteConfirmationSheet(
                                                    context,
                                                    title: 'Delete ride?',
                                                    message:
                                                        'Service totals will be recalculated.',
                                                  );
                                                  if (remove == true &&
                                                      context.mounted) {
                                                    await presentCommand(
                                                        context,
                                                        () => controller
                                                            .remove(ride.id));
                                                  }
                                                }))),
                          ]);
                    }),
              ])));
}
