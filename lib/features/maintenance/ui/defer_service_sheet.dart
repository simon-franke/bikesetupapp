import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/adaptive_modal.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/ui/failure_message.dart';
import '../controllers/service_editor_controller.dart';
import '../models/service_component.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int _kDeferDefaultKm = 50;
Future<void> showDeferServiceSheet(
        {required BuildContext context,
        required String userID,
        required ServiceComponent component,
        required double currentMileageKm}) =>
    showAdaptiveModal<void>(
        context: context,
        builder: (_) => _DeferServiceForm(
            userId: userID, component: component, mileageKm: currentMileageKm));

class _DeferServiceForm extends StatefulWidget {
  const _DeferServiceForm(
      {required this.userId, required this.component, required this.mileageKm});
  final String userId;
  final ServiceComponent component;
  final double mileageKm;
  @override
  State<_DeferServiceForm> createState() => _DeferServiceFormState();
}

class _DeferServiceFormState extends State<_DeferServiceForm> {
  late final ServiceEditorController _controller;
  int _extendKm = _kDeferDefaultKm;
  @override
  void initState() {
    super.initState();
    final dependencies = AppDependencies.of(context);
    _controller = ServiceEditorController(
        dependencies.forUser(widget.userId).maintenance,
        dependencies.stravaConnection,
        component: widget.component,
        currentMileageKm: widget.mileageKm)
      ..addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final result = await _controller.deferService(_extendKm);
      if (!mounted || !result.isSuccess) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } catch (error, stack) {
      FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final error = _controller.saveError;
    return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSheetHandle(),
              const SizedBox(height: 18),
              Center(
                  child: Text('STILL GOOD FOR',
                      style: AppTextStyles.eyebrow(color: p.inkDim))),
              const SizedBox(height: 8),
              IgnorePointer(
                  ignoring: _controller.saving,
                  child: SettingValueEditor(
                      initialValue: _kDeferDefaultKm.toDouble(),
                      min: 10,
                      max: 500,
                      step: 1,
                      decimals: 0,
                      unitLabel: 'km',
                      onChanged: (value) => _extendKm = value.round())),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                    error is AppFailure && error.code != FailureCode.saveFailed
                        ? failureMessage(error)
                        : 'Could not save service. Try again.',
                    style: TextStyle(color: p.red)),
              ],
              const SizedBox(height: 22),
              SizedBox(
                  width: double.infinity,
                  child: AppActionButton(
                      label: _controller.saving ? 'Saving…' : 'Save',
                      onPressed: _controller.saving ? null : _save)),
            ]));
  }
}
