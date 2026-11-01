import 'package:bikesetupapp/common/ui/app_select.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/features/bikes/models/new_bike_mode.dart';
import 'create_bike_flow.dart';

Future<void> showNewBikeSheet(
  BuildContext context,
  User user,
  NewBikeMode mode, {
  String uBikeID = '',
  String bikeName = '',
  String uSetupID = '',
  String setupName = '',
  required void Function(String, String, String, String) onBikeSelected,
}) =>
    showAppSheet<void>(
        context: context,
        builder: (_) => mode == NewBikeMode.newBike
            ? CreateBikeFlow(user: user, onCreated: onBikeSelected)
            : _SetupSheet(
                user: user,
                mode: mode,
                bike: uBikeID,
                bikeName: bikeName,
                setup: uSetupID,
                name: setupName,
                onSelected: onBikeSelected));

class _SetupSheet extends StatefulWidget {
  const _SetupSheet(
      {required this.user,
      required this.mode,
      required this.bike,
      required this.bikeName,
      required this.setup,
      required this.name,
      required this.onSelected});
  final User user;
  final NewBikeMode mode;
  final String bike, bikeName, setup, name;
  final void Function(String, String, String, String) onSelected;
  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  late final name =
      TextEditingController(text: widget.mode.isEdit ? widget.name : '');
  late final setups =
      AppDependencies.of(context).forUser(widget.user.uid).setups;
  late final stream = setups.getSetups(widget.bike);
  late String source = widget.setup;
  bool saving = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    final value = name.text.trim();
    if (value.isEmpty) {
      setState(() => error = 'Enter a setup name.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final id = widget.mode.isEdit ? widget.setup : const Uuid().v4();
    final saved = await presentCommand(
        context,
        () => widget.mode.isEdit
            ? setups.updateSetupInformation(widget.bike, id, value, {})
            : setups.copySetup(widget.bike, id, value, source));
    if (!mounted) return;
    setState(() => saving = false);
    if (saved) {
      Navigator.pop(context);
      widget.onSelected(widget.bikeName, widget.bike, value, id);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !saving,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
            child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSheetHandle(),
                const SizedBox(height: 20),
                Text(widget.mode.isEdit ? 'Rename setup' : 'Add setup',
                    style: AppTextStyles.heading
                        .copyWith(color: context.palette.ink)),
                const SizedBox(height: 8),
                Text(widget.bikeName,
                    style: TextStyle(color: context.palette.inkMuted)),
                const SizedBox(height: 24),
                const AppFieldLabel('Setup name'),
                const SizedBox(height: 8),
                AppTextField(
                    controller: name,
                    hint: 'Name your setup',
                    errorText: error),
                if (!widget.mode.isEdit) ...[
                  const SizedBox(height: 24),
                  const AppFieldLabel('Start from'),
                  const SizedBox(height: 8),
                  StreamBuilder(
                      stream: stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                              'Could not load setups. Reopen this form to retry.');
                        }
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        if (!snapshot.data!
                            .any((setup) => setup.id == source)) {
                          source = '';
                        }
                        return AppSelect<String>(
                            label: 'Start from',
                            value: source,
                            items: [
                              const DropdownMenuItem(
                                  value: '',
                                  child: Text('Same parts, blank values')),
                              for (final setup in snapshot.data!)
                                DropdownMenuItem(
                                    value: setup.id,
                                    child: Text('Copy ${setup.name}')),
                            ],
                            onChanged: saving
                                ? null
                                : (value) => setState(() => source = value!));
                      }),
                ],
                const SizedBox(height: 24),
                AppActionButton(
                    label: saving ? 'Saving…' : 'Save setup',
                    onPressed: saving ? null : save),
              ]),
        )),
      ));
}
