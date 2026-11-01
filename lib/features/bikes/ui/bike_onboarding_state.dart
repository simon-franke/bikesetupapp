import 'package:flutter/widgets.dart';
import '../../setups/models/setup_configuration.dart';
import '../../setups/models/unit_system.dart';
import '../../setups/ui/field_meta.dart';
import '../models/bike_creation_draft.dart';

enum OnboardingStepKind { name, parts, controls, settings }

typedef OnboardingStep = ({OnboardingStepKind kind, String category});

/// Form state and navigation, independent of the onboarding widget tree.
/// Fields are initialized on entry to a step; reading a field never resets it.
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
  // Keep the name and parts stages fixed while choices change the later steps.
  // Once parts are chosen, distribute the remaining progress across their pages.
  double get progress =>
      step < 2 ? (step + 1) * .1 : .2 + .8 * (step - 1) / (steps.length - 2);

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
          '$category/$field', () => TextEditingController(text: ''));
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
    if (seededSteps.add(destination) && destination.category == 'RearTire') {
      settings.putIfAbsent(
          'RearTire/Pressure',
          () => TextEditingController(
              text: settings['FrontTire/Pressure']?.text ?? ''));
      if (rearWheel.isEmpty) rearWheel = frontWheel;
    }
    step = next;
    error = null;
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
      if (travel.isNotEmpty && (number == null || !number.isFinite)) {
        error = 'Travel: enter a number, or leave it blank.';
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
        if (value == null || !value.isFinite) {
          error = '$field: enter a number, or leave it blank.';
          return false;
        }
      }
    }
    return true;
  }
}
