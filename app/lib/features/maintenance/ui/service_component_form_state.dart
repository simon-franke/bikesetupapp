import 'package:flutter/material.dart';
import '../models/component_type.dart';
import '../models/service_icon.dart';

class ServiceComponentDraft {
  const ServiceComponentDraft(
      {required this.name,
      required this.kmInterval,
      required this.hourInterval,
      required this.hours,
      required this.icon,
      required this.initialHours,
      required this.initialKm});

  final String name, kmInterval, hourInterval, initialHours, initialKm;
  final bool hours;
  final ServiceIcon icon;
}

class ServiceComponentFormState {
  ComponentType? selectedType;
  ServiceIcon customIcon = ServiceIcon.tools;
  final Map<ComponentType, ServiceComponentDraft> _drafts = {};
  String _kmInterval = '', _hourInterval = '';
  bool hours = false, includeIndoor = false;
  String? nameError, intervalError, usageError;
  bool submitted = false;
  final initialHours = TextEditingController(text: '0');
  final initialKm = TextEditingController(text: '0');
  final TextEditingController nameController = TextEditingController();
  final TextEditingController intervalController = TextEditingController();

  void dispose() {
    initialHours.dispose();
    initialKm.dispose();
    nameController.dispose();
    intervalController.dispose();
  }

  void selectType(ComponentType type) {
    if (selectedType != null) {
      _rememberInterval();
      _drafts[selectedType!] = ServiceComponentDraft(
        name: nameController.text,
        kmInterval: _kmInterval,
        hourInterval: _hourInterval,
        hours: hours,
        icon: customIcon,
        initialHours: initialHours.text,
        initialKm: initialKm.text,
      );
    }

    final draft = _drafts[type];
    submitted = false;
    nameError = intervalError = usageError = null;
    selectedType = type;
    customIcon = draft?.icon ?? ServiceIcon.forType(type);
    initialHours.text = draft?.initialHours ?? '0';
    initialKm.text = draft?.initialKm ?? '0';
    nameController.text =
        draft?.name ?? (type == ComponentType.other ? '' : type.label);
    _kmInterval = draft?.kmInterval ?? '';
    _hourInterval = draft?.hourInterval ?? '';
    hours = draft?.hours ??
        (type == ComponentType.forkServiceLower ||
            type == ComponentType.forkServiceFull ||
            type == ComponentType.shockService);
    intervalController.text = hours ? _hourInterval : _kmInterval;
  }

  void _rememberInterval() {
    if (hours) {
      _hourInterval = intervalController.text;
    } else {
      _kmInterval = intervalController.text;
    }
  }

  void changeUnit(bool hours) {
    _rememberInterval();
    this.hours = hours;
    intervalController.text = hours ? _hourInterval : _kmInterval;
    if (submitted) validate();
  }

  bool validate() {
    final interval = double.tryParse(intervalController.text.trim());
    final usageText = (hours ? initialHours : initialKm).text.trim();
    final usage = usageText.isEmpty
        ? 0.0
        : double.tryParse(usageText.replaceAll(',', '.'));
    submitted = true;
    nameError =
        nameController.text.trim().isEmpty ? 'Enter a component name.' : null;
    intervalError = interval == null ||
            !interval.isFinite ||
            interval <= 0 ||
            (!hours && interval % 1 != 0)
        ? (hours
            ? 'Enter the riding time between services.'
            : 'Enter the distance between services.')
        : null;
    usageError = usage == null || !usage.isFinite || usage < 0
        ? 'Enter how much it has already been used, or leave it blank.'
        : null;

    return nameError == null && intervalError == null && usageError == null;
  }

  double get interval => double.parse(intervalController.text.trim());

  double get initialUsage {
    final text = (hours ? initialHours : initialKm).text.trim();
    return text.isEmpty ? 0 : double.parse(text.replaceAll(',', '.'));
  }
}
