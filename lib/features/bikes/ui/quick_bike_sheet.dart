import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../models/bike_creation_draft.dart';
import '../../setups/models/setup_configuration.dart';
import '../../setups/ui/field_meta.dart';

class QuickBikeSheet extends StatefulWidget {
  const QuickBikeSheet(
      {super.key,
      required this.user,
      required this.onCreated,
      this.isSheet = true});
  final User user;
  final bool isSheet;
  final void Function(String, String, String, String, SetupConfiguration)
      onCreated;
  @override
  State<QuickBikeSheet> createState() => _QuickBikeSheetState();
}

class _QuickBikeSheetState extends State<QuickBikeSheet> {
  final name = TextEditingController();
  bool saving = false;
  String? error;
  OverlayEntry? _loadingOverlay;
  @override
  void dispose() {
    _removeLoading();
    name.dispose();
    super.dispose();
  }

  void _removeLoading() {
    _loadingOverlay?.remove();
    _loadingOverlay?.dispose();
    _loadingOverlay = null;
  }

  void _showLoading() {
    final background = context.palette.bg;
    _loadingOverlay = OverlayEntry(
        builder: (_) => Positioned.fill(
              child: BlockSemantics(
                  child: AbsorbPointer(
                      child: Material(
                          color: background,
                          child: const SafeArea(
                              child: Center(
                                  child: AppLoadingState(
                                      label: 'Adding bike…')))))),
            ));
    Overlay.of(context, rootOverlay: true).insert(_loadingOverlay!);
  }

  BikeCreationDraft get draft => BikeCreationDraft(
      name: name.text,
      configuration: SetupConfiguration({
        'FrontTire': ['Pressure'],
        'RearTire': ['Pressure'],
        'Cockpit': cockpitFields,
        'Saddle': saddleFields,
      }));
  bool validateName() {
    if (name.text.trim().isEmpty || name.text.trim().length > 100) {
      setState(() => error = 'Enter a bike name of up to 100 characters.');
      return false;
    }
    return true;
  }

  Future<void> create() async {
    if (saving) return;
    if (!validateName()) return;
    FocusScope.of(context).unfocus();
    final reviewed = draft;
    setState(() {
      saving = true;
      error = null;
    });
    _showLoading();
    String? bikeId, setupId;
    final success = await presentCommand(context, () async {
      final result = await AppDependencies.of(context)
          .forUser(widget.user.uid)
          .bikes
          .createFromDraft(reviewed, setupName: 'Baseline');
      if (result.isSuccess) {
        bikeId = result.requireValue().bikeId;
        setupId = result.requireValue().setupId;
      }
      return result;
    });
    if (!mounted) return;
    if (success) {
      final onCreated = widget.onCreated;
      if (widget.isSheet) await dismissAppSheet(context);
      onCreated(
          reviewed.name, bikeId!, 'Baseline', setupId!, reviewed.configuration);
    }
    _removeLoading();
    if (mounted) setState(() => saving = false);
  }

  Widget get form => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
              title: widget.isSheet ? 'Add a bike' : 'What do you ride?',
              showHandle: widget.isSheet),
          const AppFieldLabel('Bike name'),
          const SizedBox(height: 8),
          IgnorePointer(
              ignoring: saving,
              child: AppTextField(
                  controller: name, hint: 'Name or model', errorText: error)),
        ],
      );

  Widget get action => AppTactileButton(
      onPressed: saving ? null : create, child: const Text('Add bike'));

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !saving,
        child: widget.isSheet
            ? Padding(
                padding: appSheetPadding(context),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [form, const SizedBox(height: 32), action]))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                    child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: form,
                )),
                Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: action),
              ]),
      );
}
