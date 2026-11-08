import '../../setups/models/unit_system.dart';
import '../../setups/ui/setting_unit_selector.dart';
import 'package:bikesetupapp/common/ui/app_date_sheet.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/rides_controller.dart';
import '../models/ride.dart';

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
                    AppFormField(
                        label: 'Date & time',
                        child: AppValueButton(
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
                                  })),
                    const SizedBox(height: 12),
                    AppFormField(
                        label: 'Distance',
                        child: AppTextField(
                            key: const ValueKey('ride-distance'),
                            controller: distance,
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (text) => setState(() {
                                  final value = double.tryParse(
                                      text.replaceAll(',', '.'));
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
                                    setState(() =>
                                        error = 'Enter a positive distance.');
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
                                }))),
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
                    AppFormField(
                        label: 'Riding time',
                        child: Row(children: [
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
                        ])),
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
                        isLoading: saving,
                        loadingLabel: 'Saving…',
                        label: 'Save ride',
                        onPressed: saving ? null : save),
                  ]))));
}
