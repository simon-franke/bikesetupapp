import 'package:bikesetupapp/common/ui/app_date_sheet.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
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
  Widget build(BuildContext context) => Padding(
      padding: appSheetPadding(context),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(
                title: 'Log service', subtitle: widget.component.name),
            Text('Ride hours restart from this service.',
                style: AppTextStyles.body
                    .copyWith(color: context.palette.inkMuted)),
            const SizedBox(height: 20),
            const AppFieldLabel('Date & time'),
            const SizedBox(height: 8),
            AppValueButton(
                label: DateFormat.yMMMd().add_Hm().format(date),
                onTap: saving
                    ? null
                    : () async {
                        final selected = await pickAppDate(context,
                            initial: date, includeTime: true);
                        if (selected == null || !mounted) return;
                        setState(() => date = selected);
                      }),
            const SizedBox(height: 20),
            const AppFieldLabel('Note (optional)'),
            const SizedBox(height: 8),
            AppTextField(controller: note, hint: 'What was done?', maxLines: 3),
            const SizedBox(height: 24),
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
          ]));
}
