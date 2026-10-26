import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/adaptive_modal.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../models/service_component.dart';

class HourServiceSheet extends StatefulWidget {
  const HourServiceSheet(
      {super.key, required this.uid, required this.component});
  final String uid;
  final ServiceComponent component;
  @override
  State<HourServiceSheet> createState() => _HourServiceSheetState();
}

class _HourServiceSheetState extends State<HourServiceSheet> {
  final note = TextEditingController();
  final entryId = const Uuid().v4();
  DateTime date = DateTime.now();
  bool saving = false;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppSheetHandle(),
                    const SizedBox(height: 20),
                    Text('Service for ${widget.component.name}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    const Text(
                        'Ride hours restart from the time this service was completed. Earlier rides stay in your ride log.'),
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final day = await showDatePicker(
                                    context: context,
                                    initialDate: date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now());
                                if (day == null || !context.mounted) return;
                                final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(date));
                                if (time == null || !context.mounted) return;
                                final selected = DateTime(day.year, day.month,
                                    day.day, time.hour, time.minute);
                                if (selected.isAfter(DateTime.now())) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Choose a service time in the past.')));
                                  return;
                                }
                                setState(() => date = selected);
                              },
                        child: Text(DateFormat.yMMMd().add_Hm().format(date))),
                    AppTextField(
                        controller: note,
                        hint: 'Service note (optional)',
                        maxLines: 3),
                    const SizedBox(height: 20),
                    AppActionButton(
                        label: saving ? 'Saving…' : 'Log service',
                        onPressed: saving
                            ? null
                            : () async {
                                setState(() => saving = true);
                                final saved = await presentCommand(
                                    context,
                                    () => AppDependencies.of(context)
                                        .forUser(widget.uid)
                                        .maintenance
                                        .logService(
                                            componentId: widget.component.id,
                                            date: date,
                                            initialRideHours: 0,
                                            note: note.text,
                                            entryId: entryId));
                                if (!context.mounted) return;
                                if (saved) {
                                  Navigator.pop(context);
                                } else {
                                  setState(() => saving = false);
                                }
                              }),
                  ]))));
}
