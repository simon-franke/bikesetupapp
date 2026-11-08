import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';

class ExperimentNameSheet extends StatefulWidget {
  const ExperimentNameSheet(
      {super.key,
      required this.initial,
      this.title = 'Save as new setup',
      this.action = 'Create setup'});

  final String initial, title, action;

  @override
  State<ExperimentNameSheet> createState() => ExperimentNameSheetState();
}

class ExperimentNameSheetState extends State<ExperimentNameSheet> {
  late final text = TextEditingController(text: widget.initial)
    ..selection =
        TextSelection(baseOffset: 0, extentOffset: widget.initial.length);

  void submit() {
    if (text.text.trim().isNotEmpty) {
      Navigator.pop(context, text.text.trim());
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: appSheetPadding(context),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(title: widget.title),
            AppTextField(
                controller: text,
                hint:
                    widget.action == 'Done' ? 'Experiment name' : 'Setup name',
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 24),
            AppActionButton(
                label: widget.action,
                onPressed: text.text.trim().isEmpty ? null : submit),
          ]));
}
