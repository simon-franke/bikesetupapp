import 'package:flutter/widgets.dart';
import '../../setups/models/setup_configuration.dart';
import '../../setups/models/unit_system.dart';
import '../../setups/ui/field_meta.dart';
import '../models/bike_creation_draft.dart';

enum OnboardingStepKind { name, parts, controls, settings }

typedef OnboardingStep = ({OnboardingStepKind kind, String category});

/// Form state and navigation, independent of the onboarding widget tree.
/// Defaults are initialized on entry to a step; reading a field never resets it.
class BikeOnboardingState {
  final BikeCreationDraft? initialDraft;
  final name = TextEditingController();
  final forkModel = TextEditingController();
  final shockModel = TextEditingController();
  final forkTravel = TextEditingController();
  final shockTravel = TextEditingController();
  final frameReach = TextEditingController();
  final frameStack = TextEditingController();
  String fork = 'None', shock = 'None';
  String lastForkSpring = 'Air', lastShockSpring = 'Air';
  String frontWheel = '', rearWheel = '';
  final forkAdjusters = <String>{'Rebound', 'Compression'};
  final shockAdjusters = <String>{'Rebound', 'Compression'};
  bool cockpit = true, saddle = true, frame = false;
  int step = 0;
  final seededSteps = <OnboardingStep>{};
  String? error;
  final settings = <String, TextEditingController>{};
  List<OnboardingStep> get steps => [
        (kind: OnboardingStepKind.name, category: ''),
        (kind: OnboardingStepKind.parts, category: ''),
        for (final category in configuredFields.keys) ...[
          if (category == 'Fork' || category == 'Shock')
            (kind: OnboardingStepKind.controls, category: category),
          (kind: OnboardingStepKind.settings, category: category),
        ],
      ];
  OnboardingStep get currentStep => steps[step];
  String get currentCategory => currentStep.category;
  List<String> get currentFields =>
      currentStep.kind == OnboardingStepKind.settings
          ? configuredFields[currentCategory] ?? []
          : [];
  double get progress {
    if (step == 0) return .06;
    if (step == 1) return .14;
    if (currentCategory == 'FrontTire') return .24;
    if (currentCategory == 'RearTire') return .34;
    final parts =
        configuredFields.keys.where((key) => !key.endsWith('Tire')).toList();
    final index = parts.indexOf(currentCategory);
    if (index < 0 || parts.isEmpty) return 1;
    final fraction = currentStep.kind == OnboardingStepKind.controls ? .2 : 1.0;
    return .34 + .66 * (index + fraction) / parts.length;
  }

  Map<String, List<String>> get configuredFields => {
        'FrontTire': ['Pressure'],
        'RearTire': ['Pressure'],
        if (fork != 'None') 'Fork': suspensionFields(fork, forkAdjusters),
        if (shock != 'None') 'Shock': suspensionFields(shock, shockAdjusters),
        if (cockpit) 'Cockpit': cockpitFields,
        if (saddle) 'Saddle': saddleFields,
        if (frame) 'Frame': frameFields,
      };
  TextEditingController setting(String category, String field) =>
      settings['$category/$field']!;

  void _initializeFields(String category, Iterable<String> fields) {
    for (final field in fields) {
      settings.putIfAbsent(
          '$category/$field',
          () => TextEditingController(
              text: initialSettingValue(category, field)));
    }
  }

  BikeOnboardingState({this.initialDraft}) {
    final draft = initialDraft;
    if (draft != null) {
      name.text = draft.name;
      for (final category in draft.values.entries) {
        for (final value in category.value.entries) {
          settings['${category.key}/${value.key}'] =
              TextEditingController(text: value.value);
        }
      }
      final specs = draft.specifications;
      fork = draft.configuration.fields.containsKey('Fork')
          ? specs['fork'] ?? 'Air'
          : 'None';
      shock = draft.configuration.fields.containsKey('Shock')
          ? specs['shock'] ?? 'Air'
          : 'None';
      lastForkSpring = fork == 'None' ? 'Air' : fork;
      lastShockSpring = shock == 'None' ? 'Air' : shock;
      forkModel.text = specs['fork_model'] ?? '';
      shockModel.text = specs['shock_model'] ?? '';
      forkTravel.text = specs['front_travel'] ?? '';
      shockTravel.text = specs['rear_travel'] ?? '';
      frameReach.text = specs['frame_reach'] ?? '';
      frameStack.text = specs['frame_stack'] ?? '';
      frontWheel = specs['front_wheel_size'] ?? '';
      rearWheel = specs['rear_wheel_size'] ?? '';
      frame = draft.configuration.fields.containsKey('Frame');
      cockpit = draft.configuration.fields.containsKey('Cockpit');
      saddle = draft.configuration.fields.containsKey('Saddle');
      for (final entry
          in {'Fork': forkAdjusters, 'Shock': shockAdjusters}.entries) {
        entry.value
          ..clear()
          ..addAll((draft.configuration.fields[entry.key] ?? []).where(
              (field) =>
                  field.contains('Rebound') || field.contains('Compression')));
      }
    }
  }

  void dispose() {
    for (final controller in [
      name,
      forkModel,
      shockModel,
      forkTravel,
      shockTravel,
      frameReach,
      frameStack
    ]) {
      controller.dispose();
    }
    for (final controller in settings.values) {
      controller.dispose();
    }
  }

  BikeCreationDraft get draft => BikeCreationDraft(
        name: name.text,
        configuration: SetupConfiguration(configuredFields),
        values: {
          for (final category in configuredFields.entries)
            category.key: {
              for (final field in category.value)
                if ((settings['${category.key}/$field']?.text.trim() ?? '')
                    .isNotEmpty)
                  field: settings['${category.key}/$field']!.text.trim(),
            }
        },
        specifications: {
          'fork': fork,
          'shock': shock,
          if (fork != 'None') ...{
            'fork_model': forkModel.text.trim(),
            'front_travel': forkTravel.text.trim(),
          },
          if (shock != 'None') ...{
            'shock_model': shockModel.text.trim(),
            'rear_travel': shockTravel.text.trim(),
          },
          'front_wheel_size': frontWheel,
          'rear_wheel_size': rearWheel,
          'frame_reach': frameReach.text.trim(),
          'frame_stack': frameStack.text.trim(),
        },
      );

  void go(int next) {
    final destination = steps[next];
    if (seededSteps.add(destination)) {
      if (destination.category == 'RearTire') {
        if (!settings.containsKey('RearTire/Pressure')) {
          settings['RearTire/Pressure'] = TextEditingController(
              text: setting('FrontTire', 'Pressure').text);
        }
        if (rearWheel.isEmpty) rearWheel = frontWheel;
      } else if (destination.category == 'Shock' &&
          destination.kind == OnboardingStepKind.controls &&
          fork != 'None') {
        if (!(initialDraft?.configuration.fields.containsKey('Shock') ??
            false)) {
          shockAdjusters
            ..clear()
            ..addAll(forkAdjusters);
        }
        if (shockTravel.text.isEmpty) shockTravel.text = forkTravel.text;
      } else if (destination.category == 'Shock' &&
          destination.kind == OnboardingStepKind.settings &&
          fork != 'None') {
        // Pressure and spring rate are component-specific, not interchangeable.
        for (final field in configuredFields['Shock'] ?? <String>[]) {
          if (field.contains('Rebound') || field.contains('Compression')) {
            final source = settings['Fork/$field'];
            if (source != null && !settings.containsKey('Shock/$field')) {
              settings['Shock/$field'] =
                  TextEditingController(text: source.text);
            }
          }
        }
      }
    }
    step = next;
    error = null;
    if (currentStep.kind == OnboardingStepKind.controls) {
      final travel = currentCategory == 'Fork' ? forkTravel : shockTravel;
      if (travel.text.isEmpty) travel.text = '150';
    }
    _initializeFields(currentCategory, currentFields);
  }

  bool validate() {
    if (step == 0 &&
        (name.text.trim().isEmpty || name.text.trim().length > 100)) {
      error = 'Enter a bike name (up to 100 characters).';
      return false;
    }
    if (currentStep.kind == OnboardingStepKind.controls) {
      final travel =
          (currentCategory == 'Fork' ? forkTravel : shockTravel).text.trim();
      final number = double.tryParse(travel);
      if (travel.isNotEmpty &&
          (number == null || !number.isFinite || number <= 0 || number > 300)) {
        error =
            'Travel: enter a value between 0 and 300 mm, or leave it blank.';
        return false;
      }
    }
    for (final field in currentFields) {
      final text = setting(currentCategory, field).text.trim();
      final meta = kFieldMeta[field] ?? kDefaultFieldMeta;
      if (text.isNotEmpty && meta.family != UnitFamily.freeText) {
        final parsed = SettingValue.parse(text,
            fallbackFamily: meta.family, fallbackUnit: meta.defaultUnit);
        final value = parsed.number == null
            ? null
            : convertValue(parsed.number!, parsed.unit ?? meta.defaultUnit,
                meta.defaultUnit);
        if (value == null ||
            !value.isFinite ||
            value < meta.min ||
            value > meta.max) {
          error =
              '$field: enter ${meta.min.toStringAsFixed(0)} to ${meta.max.toStringAsFixed(0)} ${meta.defaultUnitLabel}.';
          return false;
        }
      }
    }
    return true;
  }
}
