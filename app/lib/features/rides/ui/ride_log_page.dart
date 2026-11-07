import 'package:bikesetupapp/common/ui/delete_confirmation_sheet.dart';
import '../../setups/models/unit_system.dart';
import 'bike_mileage_panel.dart';
import '../../setups/ui/setting_unit_selector.dart';
import 'package:bikesetupapp/common/ui/app_date_sheet.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/rides_controller.dart';
import '../models/ride.dart';
import '../models/fit_activity_decoder.dart';

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
      final file = await openFile(acceptedTypeGroups: const [
        XTypeGroup(
            label: 'FIT activities',
            extensions: ['fit'],
            uniformTypeIdentifiers: ['public.data'])
      ]);
      if (file == null || !mounted) return;
      if (await file.length() > FitActivityDecoder.maxBytes) {
        throw const FormatException('Choose a FIT file smaller than 20 MB.');
      }
      final rides =
          await compute(FitActivityDecoder.decode, await file.readAsBytes());
      if (!mounted) return;
      final confirmed = await showAppSheet<bool>(
          context: context,
          builder: (ctx) => SafeArea(
              top: false,
              child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Import into ${widget.bikeName}',
                                style: Theme.of(ctx).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            for (final ride in rides)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(DateFormat.yMMMd()
                                      .add_Hm()
                                      .format(ride.startedAt.toLocal())),
                                  subtitle: Text('${[
                                    if (ride.distanceKm != null)
                                      '${ride.distanceKm!.toStringAsFixed(1)} km',
                                    if (ride.durationSeconds > 0)
                                      '${ride.hours.toStringAsFixed(2)} hours'
                                  ].join(' · ')}, ${ride.indoor ? 'Indoor' : 'Outdoor'}')),
                            const Text(
                                'Active riding time only. Previously imported rides are skipped.'),
                            const SizedBox(height: 20),
                            AppActionButton(
                                label: 'Import ${rides.length} rides',
                                onPressed: () => Navigator.pop(ctx, true)),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                          ])))));
      if (confirmed != true || !mounted) return;
      var inserted = 0;
      final saved = await presentCommand(context, () async {
        final result = await controller
            .save(rides.map((r) => r.forBike(widget.bikeId)).toList());
        if (result.isSuccess) inserted = result.requireValue();
        return result;
      });
      if (saved && mounted) {
        setState(() => message =
            '$inserted rides imported. ${rides.length - inserted} duplicates skipped.');
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
      if (mounted) {
        setState(() => message =
            'Could not read this file. Choose a valid activity FIT file and try again.');
      }
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
                        return const Center(child: CircularProgressIndicator());
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

class ManualRideForm extends StatefulWidget {
  const ManualRideForm(
      {super.key,
      required this.controller,
      required this.bikeId,
      required this.bikeName});
  final RidesController controller;
  final String bikeId, bikeName;
  @override
  State<ManualRideForm> createState() => _ManualRideFormState();
}

class _ManualRideFormState extends State<ManualRideForm> {
  final id = const Uuid().v4();
  final name = TextEditingController();
  final hours = TextEditingController();
  final minutes = TextEditingController();
  final distance = TextEditingController();
  UnitDef distanceUnit = unitDefById(UnitFamily.distance, 'km');
  double? distanceKm;
  bool distanceInStrava = false;
  DateTime date = DateTime.now();
  bool indoor = false, saving = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    hours.dispose();
    minutes.dispose();
    distance.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    final h = int.tryParse(hours.text.trim().isEmpty ? '0' : hours.text);
    final m = int.tryParse(minutes.text.trim().isEmpty ? '0' : minutes.text);
    if (h == null ||
        m == null ||
        h < 0 ||
        h > 168 ||
        m < 0 ||
        m > 59 ||
        h * 60 + m > 10080) {
      setState(() => error = 'Enter hours and minutes (0–59), up to 7 days.');
      return;
    }
    if (distance.text.trim().isNotEmpty &&
        (distanceKm == null || !distanceKm!.isFinite || distanceKm! <= 0)) {
      setState(() => error = 'Enter a positive distance.');
      return;
    }
    if (h * 60 + m == 0 && distanceKm == null) {
      setState(() => error = 'Enter distance, riding time, or both.');
      return;
    }
    setState(() => saving = true);
    final saved = await presentCommand(
        context,
        () => widget.controller.save([
              Ride(
                  id: id,
                  bikeId: widget.bikeId,
                  startedAt: date.toUtc(),
                  durationSeconds: h * 3600 + m * 60,
                  source: 'manual',
                  distanceKm: distanceKm,
                  distanceInStrava: distanceInStrava,
                  name: name.text.trim(),
                  indoor: indoor)
            ]));
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppSheetHandle(),
                    const SizedBox(height: 20),
                    Text('Log ride',
                        style: AppTextStyles.heading
                            .copyWith(color: context.palette.ink)),
                    const SizedBox(height: 8),
                    Text(widget.bikeName,
                        style: AppTextStyles.body
                            .copyWith(color: context.palette.inkMuted)),
                    const SizedBox(height: 20),
                    AppTextField(
                        controller: name, hint: 'Ride name (optional)'),
                    const SizedBox(height: 12),
                    const AppFieldLabel('Date & time'),
                    const SizedBox(height: 8),
                    AppValueButton(
                        label: DateFormat.yMMMd().add_Hm().format(date),
                        onTap: saving
                            ? null
                            : () async {
                                final selected = await pickAppDate(context,
                                    initial: date, includeTime: true);
                                if (selected != null && mounted) {
                                  setState(() {
                                    date = selected;
                                    error = null;
                                  });
                                }
                              }),
                    const SizedBox(height: 12),
                    const AppFieldLabel('Distance'),
                    const SizedBox(height: 8),
                    AppTextField(
                        key: const ValueKey('ride-distance'),
                        controller: distance,
                        hint: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (text) => setState(() {
                              final value =
                                  double.tryParse(text.replaceAll(',', '.'));
                              distanceKm = value == null
                                  ? null
                                  : value * distanceUnit.toCanonical;
                            }),
                        suffixWidget: SettingUnitSelector(
                            family: UnitFamily.distance,
                            unit: distanceUnit,
                            onChanged: (unit) {
                              if (distance.text.trim().isNotEmpty &&
                                  (distanceKm == null ||
                                      !distanceKm!.isFinite)) {
                                setState(
                                    () => error = 'Enter a positive distance.');
                                return;
                              }
                              setState(() {
                                distanceUnit = unit;
                                if (distanceKm != null) {
                                  distance.text =
                                      (distanceKm! / unit.toCanonical)
                                          .toStringAsFixed(2);
                                }
                              });
                            })),
                    if (distance.text.trim().isNotEmpty)
                      SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Already included in Strava'),
                          value: distanceInStrava,
                          onChanged: saving
                              ? null
                              : (value) =>
                                  setState(() => distanceInStrava = value)),
                    const SizedBox(height: 12),
                    const AppFieldLabel('Riding time'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: AppTextField(
                              key: const ValueKey('ride-hours'),
                              controller: hours,
                              hint: 'Hours',
                              suffix: 'h',
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: AppTextField(
                              key: const ValueKey('ride-minutes'),
                              controller: minutes,
                              hint: 'Minutes',
                              suffix: 'min',
                              keyboardType: TextInputType.number))
                    ]),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Indoor ride'),
                        value: indoor,
                        onChanged:
                            saving ? null : (v) => setState(() => indoor = v)),
                    if (error != null)
                      Text(error!,
                          style: TextStyle(color: context.palette.red)),
                    const SizedBox(height: 16),
                    AppActionButton(
                        label: saving ? 'Saving…' : 'Save ride',
                        onPressed: saving ? null : save),
                  ]))));
}
