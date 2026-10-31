import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'app_components.dart';
import 'app_sheet.dart';

Future<DateTime?> pickAppDate(BuildContext context,
    {required DateTime initial, bool includeTime = false}) {
  FocusScope.of(context).unfocus();
  return showAppSheet<DateTime>(
      context: context,
      builder: (_) =>
          _AppDateSheet(initial: initial, includeTime: includeTime));
}

class _AppDateSheet extends StatefulWidget {
  const _AppDateSheet({required this.initial, required this.includeTime});
  final DateTime initial;
  final bool includeTime;
  @override
  State<_AppDateSheet> createState() => _AppDateSheetState();
}

class _AppDateSheetState extends State<_AppDateSheet> {
  late DateTime selected = widget.initial;
  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSheetHandle(),
            const SizedBox(height: 24),
            Text(widget.includeTime ? 'Date & time' : 'Date',
                style: AppTextStyles.inter(
                    size: 22,
                    weight: FontWeight.w600,
                    color: context.palette.ink)),
            const SizedBox(height: 16),
            SizedBox(
                height: 216,
                child: CupertinoTheme(
                    data: CupertinoThemeData(
                        brightness: Theme.of(context).brightness,
                        primaryColor: context.palette.accentText,
                        textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: AppTextStyles.inter(
                                size: 18, color: context.palette.ink))),
                    child: CupertinoDatePicker(
                        initialDateTime: widget.initial,
                        minimumDate: DateTime(2000),
                        maximumDate: DateTime.now(),
                        mode: widget.includeTime
                            ? CupertinoDatePickerMode.dateAndTime
                            : CupertinoDatePickerMode.date,
                        use24hFormat:
                            MediaQuery.alwaysUse24HourFormatOf(context),
                        onDateTimeChanged: (value) => selected = value))),
            const SizedBox(height: 16),
            AppActionButton(
                label: 'Done',
                onPressed: () => Navigator.pop(context, selected)),
          ]));
}
