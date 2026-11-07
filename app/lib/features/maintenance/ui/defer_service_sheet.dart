import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
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
    showAppSheet<void>(
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
    final error = _controller.saveError;

    return Padding(
        padding: appSheetPadding(context),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSheetHeader(
                  title: 'Defer service',
                  subtitle:
                      'How much further is ${widget.component.name.toLowerCase()} good for?'),
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
              const SizedBox(height: 24),
              AppFormFooter(
                  label: 'Defer service',
                  isLoading: _controller.saving,
                  error: error == null
                      ? null
                      : error is AppFailure &&
                              error.code != FailureCode.saveFailed
                          ? failureMessage(error)
                          : 'Could not save service. Try again.',
                  onPressed: _save),
            ]));
  }
}
