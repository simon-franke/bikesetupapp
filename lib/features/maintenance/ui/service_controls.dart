import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';

class ServiceIntervalSheet extends StatefulWidget {
  const ServiceIntervalSheet(
      {super.key, required this.initial, required this.hours});
  final double initial;
  final bool hours;
  @override
  State<ServiceIntervalSheet> createState() => _ServiceIntervalSheetState();
}

class _ServiceIntervalSheetState extends State<ServiceIntervalSheet> {
  late final text = TextEditingController(
      text: widget.initial % 1 == 0
          ? widget.initial.toInt().toString()
          : widget.initial.toString());
  String? error;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 +
              MediaQuery.viewInsetsOf(context).bottom +
              MediaQuery.paddingOf(context).bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSheetHandle(),
            const SizedBox(height: 24),
            Text('Service interval',
                style:
                    AppTextStyles.heading.copyWith(color: context.palette.ink)),
            const SizedBox(height: 24),
            AppTextField(
                controller: text,
                hint: widget.hours ? 'Ride hours' : 'Kilometres',
                suffix: widget.hours ? 'h' : 'km',
                errorText: error,
                onChanged: (input) {
                  final value = double.tryParse(input.trim());
                  if (error != null &&
                      value != null &&
                      value.isFinite &&
                      value > 0 &&
                      (widget.hours || value % 1 == 0)) {
                    setState(() => error = null);
                  }
                },
                keyboardType:
                    TextInputType.numberWithOptions(decimal: widget.hours)),
            const SizedBox(height: 24),
            AppActionButton(
                label: 'Save',
                onPressed: () {
                  final value = double.tryParse(text.text.trim());
                  if (value == null ||
                      !value.isFinite ||
                      value <= 0 ||
                      (!widget.hours && value % 1 != 0)) {
                    setState(() => error = widget.hours
                        ? 'Enter the riding time between services.'
                        : 'Enter the distance between services.');
                    return;
                  }
                  Navigator.pop(context, value);
                }),
          ]));
}
