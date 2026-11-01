import '../models/service_component.dart';
import 'package:bikesetupapp/common/ui/app_error_banner.dart';
import '../models/service_icon.dart';
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
          return const Center(child: CircularProgressIndicator.adaptive());
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

  ComponentType? _selectedType;
  ServiceIcon _customIcon = ServiceIcon.tools;
  int _step = 0;
  final Map<ComponentType,
      (String, String, String, bool, ServiceIcon, String, String)> _drafts = {};
  String _kmInterval = '', _hourInterval = '';
  bool _saving = false;
  bool _hours = false, _includeIndoor = false;
  String? _error, _nameError, _intervalError, _usageError;
  bool _submitted = false;
  final _initialHours = TextEditingController(text: '0');
  final _initialKm = TextEditingController(text: '0');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();

  @override
  void dispose() {
    _initialHours.dispose();
    _initialKm.dispose();
    _nameController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _onTypeSelected(ComponentType type) {
    if (_selectedType != null) {
      _rememberInterval();
      _drafts[_selectedType!] = (
        _nameController.text,
        _kmInterval,
        _hourInterval,
        _hours,
        _customIcon,
        _initialHours.text,
        _initialKm.text,
      );
    }
    final draft = _drafts[type];
    setState(() {
      _submitted = false;
      _nameError = _intervalError = _usageError = null;
      _selectedType = type;
      _customIcon = draft?.$5 ?? ServiceIcon.forType(type);
      _initialHours.text = draft?.$6 ?? '0';
      _initialKm.text = draft?.$7 ?? '0';
      _nameController.text =
          draft?.$1 ?? (type == ComponentType.other ? '' : type.label);
      _kmInterval = draft?.$2 ?? '';
      _hourInterval = draft?.$3 ?? '';
      _hours = draft?.$4 ??
          (type == ComponentType.forkServiceLower ||
              type == ComponentType.forkServiceFull ||
              type == ComponentType.shockService);
      _intervalController.text = _hours ? _hourInterval : _kmInterval;
      _error = null;
      _step = 1;
    });
  }

  void _rememberInterval() {
    if (_hours) {
      _hourInterval = _intervalController.text;
    } else {
      _kmInterval = _intervalController.text;
    }
  }

  void _changeUnit(bool hours) {
    _rememberInterval();
    setState(() {
      _hours = hours;
      _intervalController.text = hours ? _hourInterval : _kmInterval;
      _error = null;
    });
    if (_submitted) _validateInterval();
  }

  bool _validateInterval() {
    final interval = double.tryParse(_intervalController.text.trim());
    final usageText = (_hours ? _initialHours : _initialKm).text.trim();
    final usage = usageText.isEmpty
        ? 0.0
        : double.tryParse(usageText.replaceAll(',', '.'));
    setState(() {
      _submitted = true;
      _nameError = _nameController.text.trim().isEmpty
          ? 'Enter a component name.'
          : null;
      _intervalError = interval == null ||
              !interval.isFinite ||
              interval <= 0 ||
              (!_hours && interval % 1 != 0)
          ? (_hours
              ? 'Enter the riding time between services.'
              : 'Enter the distance between services.')
          : null;
      _usageError = usage == null || !usage.isFinite || usage < 0
          ? 'Enter how much it has already been used, or leave it blank.'
          : null;
    });
    return _nameError == null && _intervalError == null && _usageError == null;
  }

  void _revalidate(String _) {
    if (_submitted) _validateInterval();
  }

  Future<void> _onSave() async {
    if (_saving || _selectedType == null) return;
    final name = _nameController.text.trim();
    final interval = double.tryParse(_intervalController.text.trim()) ?? 0;
    final initialText = (_hours ? _initialHours : _initialKm).text.trim();
    final initial = initialText.isEmpty
        ? 0.0
        : double.tryParse(initialText.replaceAll(',', '.')) ?? -1;
    if (name.isEmpty ||
        !interval.isFinite ||
        interval <= 0 ||
        (!_hours && interval != interval.roundToDouble()) ||
        !initial.isFinite ||
        initial < 0) {
      setState(() => _error =
          'Enter zero or more ${_hours ? 'hours' : 'kilometres'} already used.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final db = AppDependencies.of(context).forUser(widget.uid);
    final saved = await presentCommand(
        context,
        () => db.maintenance.createComponent(
            bikeId: widget.bikeId,
            type: _selectedType!,
            customIcon: _customIcon,
            name: name,
            serviceIntervalKm: _hours ? 0 : interval.toInt(),
            serviceIntervalHours: _hours ? interval : null,
            initialRideHours: _hours ? initial : 0,
            initialDistanceKm: _hours ? 0 : initial,
            includeIndoorRides: _includeIndoor,
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
                                const AppFieldLabel('Name'),
                                const SizedBox(height: 8),
                                Row(children: [
                                  IconButton(
                                      tooltip: 'Choose icon',
                                      style: IconButton.styleFrom(
                                          backgroundColor: p.surface2,
                                          minimumSize: const Size(56, 56),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14))),
                                      icon: ServiceComponentIcon(
                                          type: ComponentType.other,
                                          customIcon: _customIcon,
                                          color: p.ink),
                                      onPressed: () async {
                                        final icon = await pickServiceIcon(
                                            context, _customIcon);
                                        if (mounted && icon != null) {
                                          setState(() => _customIcon = icon);
                                        }
                                      }),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: AppTextField(
                                          controller: _nameController,
                                          hint: 'Component name',
                                          errorText: _nameError,
                                          onChanged: _revalidate)),
                                ]),
                                const SizedBox(height: 24),
                                const AppFieldLabel('Service every'),
                                const SizedBox(height: 8),
                                AppTextField(
                                    key: const ValueKey('service-interval'),
                                    controller: _intervalController,
                                    errorText: _intervalError,
                                    onChanged: _revalidate,
                                    hint: _hours
                                        ? 'Manufacturer’s interval'
                                        : 'Distance between services',
                                    suffixWidget: AppUnitSelector(
                                        value: _hours ? 'h' : 'km',
                                        options: const [
                                          AppUnitOption(
                                              'km', 'km', 'Kilometres'),
                                          AppUnitOption('h', 'h', 'Ride hours')
                                        ],
                                        onChanged: (unit) =>
                                            _changeUnit(unit == 'h')),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: _hours)),
                                const SizedBox(height: 24),
                                const AppFieldLabel('Already used'),
                                const SizedBox(height: 8),
                                AppTextField(
                                    key: const ValueKey('already-used'),
                                    errorText: _usageError,
                                    onChanged: _revalidate,
                                    controller:
                                        _hours ? _initialHours : _initialKm,
                                    hint: '0',
                                    suffix: _hours ? 'h' : 'km',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true)),
                                const SizedBox(height: 8),
                                Text('Since the last service or installation.',
                                    style: AppTextStyles.body
                                        .copyWith(color: p.inkMuted)),
                                if (_hours)
                                  SwitchListTile.adaptive(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Include indoor rides'),
                                      value: _includeIndoor,
                                      onChanged: (value) => setState(
                                          () => _includeIndoor = value)),
                              ],
                              const SizedBox(height: 24),
                            ])))),
            if (_step > 0)
              AppFlowFooter(
                  label: _saving ? 'Adding…' : 'Add component',
                  error: _error,
                  onDismissError: () => setState(() => _error = null),
                  onPressed: _saving
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          if (_validateInterval()) _onSave();
                        }),
          ])),
        ));
  }
}
