import 'service_component_form_state.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import '../models/service_component.dart';
import 'package:bikesetupapp/common/ui/app_error_banner.dart';
import 'service_icon_picker.dart';
import 'package:bikesetupapp/common/ui/app_unit_selector.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_flow.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'service_component_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> showAddComponentFlow(
  BuildContext context, {
  required User user,
  required String uBikeID,
  required double? currentMileageKm,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
      AppRoutes.fadeSlide(AddServiceComponentFlow(
          uid: user.uid, bikeId: uBikeID, currentMileageKm: currentMileageKm)));
}

class AddServiceComponentFlow extends StatefulWidget {
  final String uid;
  final String bikeId;
  final double? currentMileageKm;

  const AddServiceComponentFlow({
    super.key,
    required this.uid,
    required this.bikeId,
    required this.currentMileageKm,
  });

  @override
  State<AddServiceComponentFlow> createState() =>
      _AddServiceComponentFlowState();
}

class _AddServiceComponentFlowState extends State<AddServiceComponentFlow> {
  Stream<List<ServiceComponent>>? _components;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _components ??= _loadComponents();
  }

  Stream<List<ServiceComponent>> _loadComponents() =>
      AppDependencies.of(context)
          .forUser(widget.uid)
          .maintenance
          .getComponentsForBike(widget.bikeId);

  Widget _componentChoices() {
    final p = context.palette;

    return StreamBuilder<List<ServiceComponent>>(
      stream: _components,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppErrorBanner(
            message: 'Couldn’t load your components.',
            onRetry: () => setState(() => _components = _loadComponents()),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: AppLoadingState());
        }

        final added = snapshot.data!.map((component) => component.type).toSet();

        return Column(children: [
          for (final type in ComponentType.values.where((type) =>
              type != ComponentType.tires &&
              (type == ComponentType.other || !added.contains(type))))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppValueButton(
                label: type == ComponentType.other ? 'Add new' : type.label,
                leading: type == ComponentType.other
                    ? Icon(CupertinoIcons.plus,
                        size: AppIconSizes.control, color: p.ink)
                    : ServiceComponentIcon(type: type, color: p.ink),
                onTap: () => _onTypeSelected(type),
              ),
            ),
        ]);
      },
    );
  }

  final form = ServiceComponentFormState();
  int _step = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }

  void _onTypeSelected(ComponentType type) => setState(() {
        form.selectType(type);
        _error = null;
        _step = 1;
      });

  void _changeUnit(bool hours) => setState(() {
        form.changeUnit(hours);
        _error = null;
      });

  void _revalidate(String _) {
    if (form.submitted) setState(form.validate);
  }

  Future<void> _onSave() async {
    if (_saving || form.selectedType == null) return;

    bool valid = false;
    setState(() => valid = form.validate());
    if (!valid) return;

    final name = form.nameController.text.trim();
    final interval = form.interval;
    final initial = form.initialUsage;

    setState(() {
      _saving = true;
      _error = null;
    });
    final db = AppDependencies.of(context).forUser(widget.uid);
    final saved = await presentCommand(
        context,
        () => db.maintenance.createComponent(
            bikeId: widget.bikeId,
            type: form.selectedType!,
            customIcon: form.customIcon,
            name: name,
            serviceIntervalKm: form.hours ? 0 : interval.toInt(),
            serviceIntervalHours: form.hours ? interval : null,
            initialRideHours: form.hours ? initial : 0,
            initialDistanceKm: form.hours ? 0 : initial,
            includeIndoorRides: form.includeIndoor,
            currentMileageKm: widget.currentMileageKm),
        onFailure: (message) => setState(() => _error = message));
    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return PopScope(
        canPop: !_saving,
        child: Scaffold(
          backgroundColor: p.surface,
          body: SafeArea(
              child: Column(children: [
            AppFlowHeader(
                progress: (_step + 1) / 2,
                progressLabel: 'Add component, step ${_step + 1} of 2',
                onBack: _step == 0 || _saving
                    ? null
                    : () => setState(() {
                          _step--;
                          _error = null;
                        }),
                onClose: _saving ? null : () => Navigator.pop(context)),
            Expanded(
                child: AbsorbPointer(
                    absorbing: _saving,
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppFlowHeading([
                                'Choose a component',
                                'Component details'
                              ][_step]),
                              Offstage(
                                  offstage: _step != 0,
                                  child: _componentChoices()),
                              if (_step == 1) ...[
                                AppFormField(
                                    label: 'Name',
                                    child: Row(children: [
                                      IconButton(
                                          tooltip: 'Choose icon',
                                          style: IconButton.styleFrom(
                                              backgroundColor: p.surface2,
                                              minimumSize: const Size(56, 56),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14))),
                                          icon: ServiceComponentIcon(
                                              type: ComponentType.other,
                                              customIcon: form.customIcon,
                                              color: p.ink),
                                          onPressed: () async {
                                            final icon = await pickServiceIcon(
                                                context, form.customIcon);
                                            if (mounted && icon != null) {
                                              setState(
                                                  () => form.customIcon = icon);
                                            }
                                          }),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: AppTextField(
                                              controller: form.nameController,
                                              hint: 'Component name',
                                              errorText: form.nameError,
                                              onChanged: _revalidate)),
                                    ])),
                                const SizedBox(height: 24),
                                AppFormField(
                                    label: 'Service every',
                                    child: AppTextField(
                                        key: const ValueKey('service-interval'),
                                        controller: form.intervalController,
                                        errorText: form.intervalError,
                                        onChanged: _revalidate,
                                        hint: form.hours
                                            ? 'Manufacturer’s interval'
                                            : 'Distance between services',
                                        suffixWidget: AppUnitSelector(
                                            value: form.hours ? 'h' : 'km',
                                            options: const [
                                              AppUnitOption(
                                                  'km', 'km', 'Kilometres'),
                                              AppUnitOption(
                                                  'h', 'h', 'Ride hours')
                                            ],
                                            onChanged: (unit) =>
                                                _changeUnit(unit == 'h')),
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                decimal: form.hours))),
                                const SizedBox(height: 24),
                                AppFormField(
                                    label: 'Already used',
                                    child: AppTextField(
                                        key: const ValueKey('already-used'),
                                        errorText: form.usageError,
                                        onChanged: _revalidate,
                                        controller: form.hours
                                            ? form.initialHours
                                            : form.initialKm,
                                        hint: '0',
                                        suffix: form.hours ? 'h' : 'km',
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true))),
                                const SizedBox(height: 8),
                                Text('Since the last service or installation.',
                                    style: AppTextStyles.body
                                        .copyWith(color: p.inkMuted)),
                                if (form.hours)
                                  SwitchListTile.adaptive(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Include indoor rides'),
                                      value: form.includeIndoor,
                                      onChanged: (value) => setState(
                                          () => form.includeIndoor = value)),
                              ],
                              const SizedBox(height: 24),
                            ])))),
            if (_step > 0)
              AppFlowFooter(
                  isLoading: _saving,
                  loadingLabel: 'Adding…',
                  label: 'Add component',
                  error: _error,
                  onDismissError: () => setState(() => _error = null),
                  onPressed: _saving
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          _onSave();
                        }),
          ])),
        ));
  }
}
