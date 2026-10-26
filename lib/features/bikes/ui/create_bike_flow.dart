import 'package:bikesetupapp/common/ui/app_select.dart';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/adaptive_modal.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import '../models/bike_creation_draft.dart';
import 'draft_value_editor.dart';
import 'draft_stepper.dart';
import 'frame_settings.dart';
import 'adjuster_dial.dart';
import '../../setups/models/unit_system.dart';

class CreateBikeFlow extends StatefulWidget {
  const CreateBikeFlow({super.key, required this.user, required this.onCreated,
      this.initialDraft});
  final User user;
  final BikeCreationDraft? initialDraft;
  final void Function(String, String, String, String) onCreated;
  @override
  State<CreateBikeFlow> createState() => _CreateBikeFlowState();
}

class _CreateBikeFlowState extends State<CreateBikeFlow> {
  final name = TextEditingController();
  final forkModel = TextEditingController();
  final shockModel = TextEditingController();
  final forkTravel = TextEditingController();
  final shockTravel = TextEditingController();
  final frameReach = TextEditingController();
  final frameStack = TextEditingController();
  final scroll = ScrollController();
  String fork = 'None', shock = 'None';
  String lastForkSpring = 'Air', lastShockSpring = 'Air';
  String frontWheel = '', rearWheel = '';
  final forkAdjusters = <String>{'Rebound', 'Compression'};
  final shockAdjusters = <String>{'Rebound', 'Compression'};
  bool cockpit = true, saddle = true, frame = false, saving = false;
  int step = 0;
  final seededSteps = <String>{};
  String? error;
  final settings = <String, TextEditingController>{};
  final editors = <String, GlobalKey<DraftValueEditorState>>{};
  final steppers = <String, GlobalKey<DraftStepperState>>{};
  List<String> get steps => ['Your bike', 'Choose parts', 'FrontTire', 'RearTire',
    for (final category in configuredFields.entries.where((entry) => !entry.key.endsWith('Tire'))) ...[
      if (category.key == 'Fork' || category.key == 'Shock') ...[
        '${category.key} controls', category.key,
      ] else category.key,
    ],
  ];
  String get currentCategory => steps[step].split(' ').first;
  List<String> get currentFields {
    final fields = configuredFields[currentCategory] ?? <String>[];
    if (steps[step].endsWith(' controls')) return [];
    return fields;
  }
  double get progress {
    if (step == 0) return .06;
    if (step == 1) return .14;
    if (steps[step] == 'FrontTire') return .24;
    if (steps[step] == 'RearTire') return .34;
    final parts = configuredFields.keys.where((key) => !key.endsWith('Tire')).toList();
    final index = parts.indexOf(currentCategory);
    if (index < 0 || parts.isEmpty) return 1;
    final fraction = steps[step].endsWith(' controls') ? .2 : 1.0;
    return .34 + .66 * (index + fraction) / parts.length;
  }
  Map<String, List<String>> get configuredFields => {
    'FrontTire': ['Pressure'], 'RearTire': ['Pressure'],
    if (fork != 'None') 'Fork': suspensionFields(fork, forkAdjusters),
    if (shock != 'None') 'Shock': suspensionFields(shock, shockAdjusters),
    if (cockpit) 'Cockpit': cockpitFields, if (saddle) 'Saddle': saddleFields,
    if (frame) 'Frame': frameFields,
  };
  TextEditingController setting(String category, String field) {
    final controller = settings.putIfAbsent('$category/$field', TextEditingController.new);
    if (controller.text.isEmpty) {
      final initial = category == 'Frame' ? switch (field) {
        'Flip chip' => 'Standard', 'Headset cups' => 'Neutral', _ => '',
      } : initialSettingValue(category, field);
      if (initial.isNotEmpty) controller.text = initial;
    }
    return controller;
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    if (draft != null) {
      name.text = draft.name;
      for (final category in draft.values.entries) {
        for (final value in category.value.entries) {
          if (value.value.isNotEmpty) setting(category.key, value.key).text = value.value;
        }
      }
      final specs = draft.specifications;
      fork = draft.configuration.fields.containsKey('Fork') ? specs['fork'] ?? 'Air' : 'None';
      shock = draft.configuration.fields.containsKey('Shock') ? specs['shock'] ?? 'Air' : 'None';
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
      for (final entry in {'Fork': forkAdjusters, 'Shock': shockAdjusters}.entries) {
        entry.value
          ..clear()
          ..addAll((draft.configuration.fields[entry.key] ?? [])
              .where((field) => field.contains('Rebound') || field.contains('Compression')));
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [name, forkModel, shockModel, forkTravel, shockTravel, frameReach, frameStack]) {
      controller.dispose();
    }
    for (final controller in settings.values) { controller.dispose(); }
    scroll.dispose();
    super.dispose();
  }

  BikeCreationDraft get draft => BikeCreationDraft(
    name: name.text,
    configuration: SetupConfiguration(configuredFields),
    values: {for (final category in configuredFields.entries)
      category.key: {for (final field in category.value)
        if (setting(category.key, field).text.trim().isNotEmpty)
          field: setting(category.key, field).text.trim(),
      }},
    specifications: {
      'fork': fork, 'shock': shock,
      if (fork != 'None') ...{
        'fork_model': forkModel.text.trim(), 'front_travel': forkTravel.text.trim(),
      },
      if (shock != 'None') ...{
        'shock_model': shockModel.text.trim(), 'rear_travel': shockTravel.text.trim(),
      },
      'front_wheel_size': frontWheel, 'rear_wheel_size': rearWheel,
      'frame_reach': frameReach.text.trim(), 'frame_stack': frameStack.text.trim(),
    },
  );

  void go(int next) {
    FocusScope.of(context).unfocus();
    final destination = steps[next];
    if (seededSteps.add(destination)) {
      if (destination == 'RearTire') {
        if (!settings.containsKey('RearTire/Pressure')) {
          setting('RearTire', 'Pressure').text = setting('FrontTire', 'Pressure').text;
        }
        if (rearWheel.isEmpty) rearWheel = frontWheel;
      } else if (destination == 'Shock controls' && fork != 'None') {
        if (!(widget.initialDraft?.configuration.fields.containsKey('Shock') ?? false)) {
          shockAdjusters..clear()..addAll(forkAdjusters);
        }
        if (shockTravel.text.isEmpty) shockTravel.text = forkTravel.text;
      } else if (destination == 'Shock' && fork != 'None') {
        // Pressure and spring rate are component-specific, not interchangeable.
        for (final field in configuredFields['Shock'] ?? <String>[]) {
          if (field.contains('Rebound') || field.contains('Compression')) {
            final source = settings['Fork/$field'];
            if (source != null && !settings.containsKey('Shock/$field')) {
              setting('Shock', field).text = source.text;
            }
          }
        }
      }
    }
    setState(() { step = next; error = null; });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  bool validate() {
    if (step == 0 && (name.text.trim().isEmpty || name.text.trim().length > 100)) {
      setState(() => error = 'Enter a bike name (up to 100 characters).');
      return false;
    }
    if (steps[step] == 'Fork controls' || steps[step] == 'Shock controls') {
      final travel = (steps[step] == 'Fork controls' ? forkTravel : shockTravel).text.trim();
      final number = double.tryParse(travel);
      if (travel.isNotEmpty && (number == null || !number.isFinite || number <= 0 || number > 300)) {
        setState(() => error = 'Travel: enter a value between 0 and 300 mm, or leave it blank.');
        return false;
      }
    }
    for (final field in currentFields) {
      final text = setting(currentCategory, field).text.trim();
      final meta = kFieldMeta[field] ?? kDefaultFieldMeta;
      if (text.isNotEmpty && meta.family != UnitFamily.freeText) {
        final parsed = SettingValue.parse(text, fallbackFamily: meta.family, fallbackUnit: meta.defaultUnit);
        final value = parsed.number == null ? null : convertValue(parsed.number!, parsed.unit ?? meta.defaultUnit, meta.defaultUnit);
        if (value == null || !value.isFinite || value < meta.min || value > meta.max) {
          setState(() => error = '$field: enter ${meta.min.toStringAsFixed(0)} to ${meta.max.toStringAsFixed(0)} ${meta.defaultUnitLabel}.');
          return false;
        }
      }
    }
    return true;
  }

  bool acceptCurrent() {
    if (steps[step].endsWith(' controls') &&
        steppers['$currentCategory/Travel']?.currentState?.accept() == false) {
      return false;
    }
    for (final field in currentFields) {
      final id = '$currentCategory/$field';
      if (editors[id]?.currentState?.accept() == false || steppers[id]?.currentState?.accept() == false) return false;
    }
    return true;
  }

  void next() {
    if (acceptCurrent() && validate()) go(step + 1);
  }

  Future<void> create() async {
    if (saving || !acceptCurrent() || !validate()) return;
    final reviewed = draft;
    setState(() => saving = true);
    String? bikeId, setupId;
    final success = await presentCommand(context, () async {
      final controllers = AppDependencies.of(context).forUser(widget.user.uid);
      final result = await controllers.bikes.createFromDraft(reviewed);
      if (!result.isSuccess) return result;
      final created = result.requireValue();
      bikeId = created.bikeId;
      setupId = created.setupId;
      return result;
    });
    if (!mounted) return;
    setState(() => saving = false);
    if (success && bikeId != null && setupId?.isNotEmpty == true) {
      Navigator.of(context).pop();
      widget.onCreated(reviewed.name, bikeId!, 'Default', setupId!);
    }
  }

  Widget field(String title, TextEditingController controller, {String? hint, bool number = false}) =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppFieldLabel(title), const SizedBox(height: 8),
          AppTextField(controller: controller, hint: hint ?? 'Optional',
              keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
              suffix: number ? 'mm' : null),
        ]));

  Widget travelSelector(TextEditingController controller) {
    if (controller.text.isEmpty) controller.text = '150';
    return DraftStepper(
      key: steppers.putIfAbsent('$currentCategory/Travel', () => GlobalKey<DraftStepperState>()),
      field: 'Travel', value: '${controller.text} mm', stepSize: 5,
      onChanged: (value) => setState(() {
        final parsed = SettingValue.parse(value, fallbackFamily: UnitFamily.length,
            fallbackUnit: kTravelFieldMeta.defaultUnit);
        controller.text = formatNumber(parsed.number ?? 150, 0);
      }),
    );
  }

  Widget wheel(String title, String value, ValueChanged<String> change) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppFieldLabel(title), const SizedBox(height: 8),
      AppSelect<String>(key: ValueKey(title), label: title, value: value,
        items: [for (final size in {'', '26', '27.5', '700C', '29', value})
          DropdownMenuItem(value: size, child: Text(size.isEmpty ? 'Choose wheel size' : size == '700C' ? '28″ / 700C' : '$size″'))],
        onChanged: (value) => setState(() => change(value!))),
    ]),
  );

  Widget adjuster(String label, Set<String> selected) {
    final low = 'Low Speed $label', high = 'High Speed $label';
    final mode = selected.contains(label) ? 'Single' : selected.contains(low) || selected.contains(high) ? 'Low / high speed' : 'None';
    Widget choice(String value, String title, int count) => Semantics(selected: mode == value,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          animationDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          side: BorderSide(color: mode == value ? context.palette.accentText : context.palette.borderStrong),
          backgroundColor: context.palette.bg,
          foregroundColor: mode == value ? context.palette.accentText : context.palette.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () => setState(() {
          selected.removeAll([label, low, high]);
          if (value == 'Single') selected.add(label);
          if (value == 'Low / high speed') selected.addAll([low, high]);
        }),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AdjusterDial(selected: mode == value, count: count),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Icon(mode == value ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
            size: 16, color: mode == value ? context.palette.accentText : context.palette.inkDim),
        ])));
    return Padding(padding: const EdgeInsets.only(bottom: 28), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(label, style: AppTextStyles.inter(size: 18, weight: FontWeight.w600, color: context.palette.ink)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final choices = [choice('None', 'None', 0), choice('Single', 'One dial', 1), choice('Low / high speed', 'Low + high', 2)];
          if (MediaQuery.textScalerOf(context).scale(13) > 20 || constraints.maxWidth < 300) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final item in choices) Padding(padding: const EdgeInsets.only(bottom: 8), child: item)]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: choices[0]), const SizedBox(width: 8), Expanded(child: choices[1]), const SizedBox(width: 8), Expanded(child: choices[2]),
          ]);
        }),
      ]));
  }

  Widget trackingPart(String title, String detail, bool selected,
      {ValueChanged<bool>? onChanged, String? spring, ValueChanged<String>? onSpringChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(selected: selected, button: onChanged != null,
        child: InkWell(onTap: onChanged == null ? null : () => onChanged(!selected),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.inter(size: 16, weight: FontWeight.w600, color: context.palette.ink)),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(detail, style: TextStyle(fontSize: 12, height: 1.4, color: context.palette.inkMuted)),
                ],
              ])),
              const SizedBox(width: 16),
              if (onChanged == null)
                Text('Included', style: TextStyle(fontSize: 12, color: context.palette.inkMuted))
              else Icon(selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                  size: 24, color: selected ? context.palette.accentText : context.palette.inkDim),
            ])),
        )),
      if (spring != null)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: selected ? 1 : 0, end: selected ? 1 : 0),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) => ClipRect(child: Align(
            alignment: Alignment.topCenter, heightFactor: value,
            child: SizedBox(width: double.infinity, child: Opacity(opacity: value, child: child)))),
          child: ExcludeSemantics(excluding: !selected, child: IgnorePointer(ignoring: !selected, child: Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: CupertinoSlidingSegmentedControl<String>(
            groupValue: spring == 'Coil' ? 'Coil' : 'Air', backgroundColor: context.palette.surface,
            thumbColor: context.palette.accent,
            children: {for (final type in ['Air', 'Coil']) type:
              Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Text(type, style: TextStyle(fontSize: 14,
                    color: spring == type ? context.palette.accentInk : context.palette.inkMuted)))},
            onValueChanged: (value) { if (value != null) onSpringChanged!(value); },
          )))),
        ),
    ]);
  }

  Widget note(String text) => Padding(padding: const EdgeInsets.only(bottom: 24),
      child: Text(text, style: AppTextStyles.inter(size: 26, weight: FontWeight.w600, color: context.palette.ink)));

  Widget ruler(String category, String key) => KeyedSubtree(key: ValueKey('$category/$key'), child: DraftValueEditor(
    key: editors.putIfAbsent('$category/$key', () => GlobalKey<DraftValueEditorState>()), field: key, value: setting(category, key).text,
    previewValue: key == 'Pressure' ? (category.endsWith('Tire') ? 25 : category == 'Fork' ? 80 : 180) : null,
    onChanged: (value) => setState(() => setting(category, key).text = value)));

  Widget tireSettings(String tire) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    ruler(tire, 'Pressure'),
    const SizedBox(height: 24),
    wheel('${tire == 'FrontTire' ? 'Front' : 'Rear'} wheel size',
      tire == 'FrontTire' ? frontWheel : rearWheel,
      (value) { if (tire == 'FrontTire') { frontWheel = value; } else { rearWheel = value; } }),
  ]);

  Widget compactValue(String field) => DraftStepper(
    key: steppers.putIfAbsent('$currentCategory/$field', () => GlobalKey<DraftStepperState>()),
    field: field, value: setting(currentCategory, field).text,
    onChanged: (value) => setState(() => setting(currentCategory, field).text = value));

  Widget groupedValues() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    note('Set your ${currentCategory.toLowerCase()}'),
    if (currentCategory == 'Frame') FrameSettings(
      values: {for (final key in currentFields) key: setting('Frame', key).text},
      onChanged: (key, value) => setState(() {
        setting('Frame', key).text = value;
      }))
    else for (final key in currentFields)
      if (key == 'Pressure' || key == 'Spring Rate') ...[
        ruler(currentCategory, key), const SizedBox(height: 24),
      ] else compactValue(key),
  ]);

  Widget page() {
    final title = steps[step];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (step == 0) ...[
        note('What’s your bike called?'),
        field('Bike name', name, hint: 'Name or model'),
      ] else if (step == 1) ...[
        note('Choose what to track'),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: context.palette.bg, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            trackingPart('Suspension fork', '', fork != 'None',
                onChanged: (enabled) => setState(() {
                  if (!enabled) lastForkSpring = fork;
                  fork = enabled ? lastForkSpring : 'None';
                }),
                spring: fork, onSpringChanged: (value) => setState(() => fork = lastForkSpring = value)),
            Divider(height: 1, indent: 18, endIndent: 18, color: context.palette.border),
            trackingPart('Rear shock', '', shock != 'None',
                onChanged: (enabled) => setState(() {
                  if (!enabled) lastShockSpring = shock;
                  shock = enabled ? lastShockSpring : 'None';
                }),
                spring: shock, onSpringChanged: (value) => setState(() => shock = lastShockSpring = value)),
            Divider(height: 1, indent: 18, endIndent: 18, color: context.palette.border),
            trackingPart('Cockpit', 'Stem, spacers and bar position', cockpit,
                onChanged: (value) => setState(() => cockpit = value)),
            Divider(height: 1, indent: 18, endIndent: 18, color: context.palette.border),
            trackingPart('Saddle', 'Height, setback and tilt', saddle,
                onChanged: (value) => setState(() => saddle = value)),
            Divider(height: 1, indent: 18, endIndent: 18, color: context.palette.border),
            trackingPart('Frame', 'Flip chip and headset cups', frame,
                onChanged: (value) => setState(() => frame = value)),
          ])),
      ] else if (title.endsWith(' controls')) ...[
        note(title.startsWith('Fork') ? 'Match your fork’s adjusters' : 'Match your shock’s adjusters'),
        sectionHeading('Adjusters'),
        adjuster('Rebound', title.startsWith('Fork') ? forkAdjusters : shockAdjusters),
        adjuster('Compression', title.startsWith('Fork') ? forkAdjusters : shockAdjusters),
        const SizedBox(height: 8),
        travelSelector(title.startsWith('Fork') ? forkTravel : shockTravel),
      ] else ...[
        if (title == 'FrontTire' || title == 'RearTire') ...[
          note(title == 'FrontTire' ? 'Set your front tire pressure' : 'Set your rear tire pressure'),
          tireSettings(title),
        ] else groupedValues(),
      ],
    ]);
  }

  Widget sectionHeading(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(header: true, child: Text(title,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: context.palette.inkMuted))),
  );

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final height = math.min(760.0, MediaQuery.sizeOf(context).height * .9 - keyboard);
    return PopScope(canPop: !saving, child: SafeArea(top: false,
      child: Padding(padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(height: math.max(180, height), child: Column(children: [
          const SizedBox(height: 12), const AppSheetHandle(),
          Padding(padding: const EdgeInsets.fromLTRB(12, 12, 20, 16), child: Row(children: [
            SizedBox(width: 48, child: step > 0 ? IconButton(tooltip: 'Back',
              onPressed: saving ? null : () => go(step - 1), icon: const Icon(CupertinoIcons.chevron_left, size: 20)) : null),
            const SizedBox(width: 8),
            Expanded(child: LinearProgressIndicator(value: progress,
              semanticsLabel: 'Bike setup progress', minHeight: 14, borderRadius: BorderRadius.circular(20),
              color: context.palette.accent, backgroundColor: context.palette.bg)),
          ])),
          Expanded(child: SingleChildScrollView(controller: scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: IgnorePointer(ignoring: saving, child: page()))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: Column(children: [
            if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12),
                child: Text(error!, style: TextStyle(color: context.palette.red, fontSize: 13))),
            Row(children: [
              Expanded(child: AppActionButton(label: saving ? 'Adding bike…' : step == steps.length - 1 ? 'Create bike' : 'Continue',
                  onPressed: saving ? null : step == steps.length - 1 ? create : next)),
            ]),
          ])),
        ])),
      ),
    ));
  }
}
