import 'package:bikesetupapp/common/ui/app_flow.dart';
import 'package:bikesetupapp/common/ui/app_select.dart';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import '../models/bike_creation_draft.dart';
import 'bike_onboarding_state.dart';
import 'draft_value_editor.dart';
import 'draft_stepper.dart';
import 'frame_settings.dart';
import 'adjuster_dial.dart';
import '../../setups/models/unit_system.dart';

class CreateBikeFlow extends StatefulWidget {
  const CreateBikeFlow(
      {super.key,
      required this.user,
      required this.onCreated,
      this.initialDraft});
  final User user;
  final BikeCreationDraft? initialDraft;
  final void Function(String, String, String, String) onCreated;
  @override
  State<CreateBikeFlow> createState() => _CreateBikeFlowState();
}

class _CreateBikeFlowState extends State<CreateBikeFlow> {
  late final flow = BikeOnboardingState(initialDraft: widget.initialDraft);
  final scroll = ScrollController();
  bool saving = false;
  final editors = <String, GlobalKey<DraftValueEditorState>>{};
  final steppers = <String, GlobalKey<DraftStepperState>>{};

  @override
  void dispose() {
    flow.dispose();
    scroll.dispose();
    super.dispose();
  }

  void go(int next) {
    FocusScope.of(context).unfocus();
    setState(() => flow.go(next));
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  bool validate() {
    final valid = flow.validate();
    setState(() {});
    return valid;
  }

  bool acceptCurrent() {
    if (flow.currentStep.kind == OnboardingStepKind.controls &&
        steppers['${flow.currentCategory}/Travel']?.currentState?.accept() ==
            false) {
      return false;
    }
    for (final field in flow.currentFields) {
      final id = '${flow.currentCategory}/$field';
      if (editors[id]?.currentState?.accept() == false ||
          steppers[id]?.currentState?.accept() == false) {
        return false;
      }
    }
    return true;
  }

  void next() {
    if (acceptCurrent() && validate()) go(flow.step + 1);
  }

  Future<void> create() async {
    if (saving || !acceptCurrent() || !validate()) return;
    final reviewed = flow.draft;
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

  Widget field(String title, TextEditingController controller,
          {String? hint, bool number = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppFieldLabel(title),
            const SizedBox(height: 8),
            AppTextField(
                controller: controller,
                hint: hint ?? 'Optional',
                keyboardType: number
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                suffix: number ? 'mm' : null),
          ]));

  Widget travelSelector(TextEditingController controller) {
    return DraftStepper(
      key: steppers.putIfAbsent('${flow.currentCategory}/Travel',
          () => GlobalKey<DraftStepperState>()),
      field: 'Travel',
      value: '${controller.text} mm',
      stepSize: 5,
      onChanged: (value) => setState(() {
        final parsed = SettingValue.parse(value,
            fallbackFamily: UnitFamily.length,
            fallbackUnit: kTravelFieldMeta.defaultUnit);
        controller.text = formatNumber(parsed.number ?? 150, 0);
      }),
    );
  }

  Widget wheel(String title, String value, ValueChanged<String> change) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppFieldLabel(title),
          const SizedBox(height: 8),
          AppSelect<String>(
              key: ValueKey(title),
              label: title,
              value: value,
              items: [
                for (final size in {'', '26', '27.5', '700C', '29', value})
                  DropdownMenuItem(
                      value: size,
                      child: Text(size.isEmpty
                          ? 'Choose wheel size'
                          : size == '700C'
                              ? '28″ / 700C'
                              : '$size″'))
              ],
              onChanged: (value) => setState(() => change(value!))),
        ]),
      );

  Widget adjuster(String label, Set<String> selected) {
    final low = 'Low Speed $label', high = 'High Speed $label';
    final mode = selected.contains(label)
        ? 'Single'
        : selected.contains(low) || selected.contains(high)
            ? 'Low / high speed'
            : 'None';
    Widget choice(String value, String title, int count) => Semantics(
        selected: mode == value,
        child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                animationDuration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                side: BorderSide(
                    color: mode == value
                        ? context.palette.accentText
                        : context.palette.borderStrong),
                backgroundColor: context.palette.bg,
                foregroundColor: mode == value
                    ? context.palette.accentText
                    : context.palette.ink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            onPressed: () => setState(() {
                  selected.removeAll([label, low, high]);
                  if (value == 'Single') selected.add(label);
                  if (value == 'Low / high speed') selected.addAll([low, high]);
                }),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AdjusterDial(selected: mode == value, count: count),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Icon(
                  mode == value
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 16,
                  color: mode == value
                      ? context.palette.accentText
                      : context.palette.inkDim),
            ])));
    return Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(label,
              style: AppTextStyles.inter(
                  size: 18,
                  weight: FontWeight.w600,
                  color: context.palette.ink)),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final choices = [
              choice('None', 'None', 0),
              choice('Single', 'One dial', 1),
              choice('Low / high speed', 'Low + high', 2)
            ];
            if (MediaQuery.textScalerOf(context).scale(13) > 20 ||
                constraints.maxWidth < 300) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in choices)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: item)
                  ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: choices[0]),
              const SizedBox(width: 8),
              Expanded(child: choices[1]),
              const SizedBox(width: 8),
              Expanded(child: choices[2]),
            ]);
          }),
        ]));
  }

  Widget trackingPart(String title, String detail, bool selected,
      {ValueChanged<bool>? onChanged,
      String? spring,
      ValueChanged<String>? onSpringChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
          selected: selected,
          button: onChanged != null,
          child: InkWell(
            onTap: onChanged == null ? null : () => onChanged(!selected),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: AppTextStyles.inter(
                                size: 16,
                                weight: FontWeight.w600,
                                color: context.palette.ink)),
                        if (detail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(detail,
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: context.palette.inkMuted)),
                        ],
                      ])),
                  const SizedBox(width: 16),
                  if (onChanged == null)
                    Text('Included',
                        style: TextStyle(
                            fontSize: 12, color: context.palette.inkMuted))
                  else
                    Icon(
                        selected
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        size: 24,
                        color: selected
                            ? context.palette.accentText
                            : context.palette.inkDim),
                ])),
          )),
      if (spring != null)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: selected ? 1 : 0, end: selected ? 1 : 0),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) => ClipRect(
              child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: value,
                  child: SizedBox(
                      width: double.infinity,
                      child: Opacity(opacity: value, child: child)))),
          child: ExcludeSemantics(
              excluding: !selected,
              child: IgnorePointer(
                  ignoring: !selected,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: spring == 'Coil' ? 'Coil' : 'Air',
                        backgroundColor: context.palette.surface,
                        thumbColor: context.palette.accent,
                        children: {
                          for (final type in ['Air', 'Coil'])
                            type: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                child: Text(type,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: spring == type
                                            ? context.palette.accentInk
                                            : context.palette.inkMuted)))
                        },
                        onValueChanged: (value) {
                          if (value != null) onSpringChanged!(value);
                        },
                      )))),
        ),
    ]);
  }

  Widget note(String text) => AppFlowHeading(text);

  Widget ruler(String category, String key) => KeyedSubtree(
      key: ValueKey('$category/$key'),
      child: DraftValueEditor(
          key: editors.putIfAbsent(
              '$category/$key', () => GlobalKey<DraftValueEditorState>()),
          field: key,
          value: flow.setting(category, key).text,
          previewValue: key == 'Pressure'
              ? (category.endsWith('Tire')
                  ? 25
                  : category == 'Fork'
                      ? 80
                      : 180)
              : null,
          onChanged: (value) =>
              setState(() => flow.setting(category, key).text = value)));

  Widget tireSettings(String tire) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ruler(tire, 'Pressure'),
        const SizedBox(height: 24),
        wheel('${tire == 'FrontTire' ? 'Front' : 'Rear'} wheel size',
            tire == 'FrontTire' ? flow.frontWheel : flow.rearWheel, (value) {
          if (tire == 'FrontTire') {
            flow.frontWheel = value;
          } else {
            flow.rearWheel = value;
          }
        }),
      ]);

  Widget compactValue(String field) => DraftStepper(
      key: steppers.putIfAbsent('${flow.currentCategory}/$field',
          () => GlobalKey<DraftStepperState>()),
      field: field,
      value: flow.setting(flow.currentCategory, field).text,
      onChanged: (value) => setState(
          () => flow.setting(flow.currentCategory, field).text = value));

  Widget groupedValues() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        note('Set your ${flow.currentCategory.toLowerCase()}'),
        if (flow.currentCategory == 'Frame')
          FrameSettings(
              values: {
                for (final key in flow.currentFields)
                  key: flow.setting('Frame', key).text
              },
              onChanged: (key, value) => setState(() {
                    flow.setting('Frame', key).text = value;
                  }))
        else
          for (final key in flow.currentFields)
            if (key == 'Pressure' || key == 'Spring Rate') ...[
              ruler(flow.currentCategory, key),
              const SizedBox(height: 24),
            ] else
              compactValue(key),
      ]);

  Widget page() {
    final title = flow.currentCategory;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (flow.step == 0) ...[
        note('What’s your bike called?'),
        field('Bike name', flow.name, hint: 'Name or model'),
      ] else if (flow.step == 1) ...[
        note('Choose what to track'),
        Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: context.palette.bg,
                borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              trackingPart('Suspension fork', '', flow.fork != 'None',
                  onChanged: (enabled) => setState(() {
                        if (!enabled) flow.lastForkSpring = flow.fork;
                        flow.fork = enabled ? flow.lastForkSpring : 'None';
                      }),
                  spring: flow.fork,
                  onSpringChanged: (value) =>
                      setState(() => flow.fork = flow.lastForkSpring = value)),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.border),
              trackingPart('Rear shock', '', flow.shock != 'None',
                  onChanged: (enabled) => setState(() {
                        if (!enabled) flow.lastShockSpring = flow.shock;
                        flow.shock = enabled ? flow.lastShockSpring : 'None';
                      }),
                  spring: flow.shock,
                  onSpringChanged: (value) => setState(
                      () => flow.shock = flow.lastShockSpring = value)),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.border),
              trackingPart(
                  'Cockpit', 'Stem, spacers and bar position', flow.cockpit,
                  onChanged: (value) => setState(() => flow.cockpit = value)),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.border),
              trackingPart('Saddle', 'Height, setback and tilt', flow.saddle,
                  onChanged: (value) => setState(() => flow.saddle = value)),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.border),
              trackingPart('Frame', 'Flip chip and headset cups', flow.frame,
                  onChanged: (value) => setState(() => flow.frame = value)),
            ])),
      ] else if (flow.currentStep.kind == OnboardingStepKind.controls) ...[
        note(title == 'Fork'
            ? 'Match your fork’s adjusters'
            : 'Match your shock’s adjusters'),
        sectionHeading('Adjusters'),
        adjuster('Rebound',
            title == 'Fork' ? flow.forkAdjusters : flow.shockAdjusters),
        adjuster('Compression',
            title == 'Fork' ? flow.forkAdjusters : flow.shockAdjusters),
        const SizedBox(height: 8),
        travelSelector(title == 'Fork' ? flow.forkTravel : flow.shockTravel),
      ] else ...[
        if (title == 'FrontTire' || title == 'RearTire') ...[
          note(title == 'FrontTire'
              ? 'Set your front tire pressure'
              : 'Set your rear tire pressure'),
          tireSettings(title),
        ] else
          groupedValues(),
      ],
    ]);
  }

  Widget sectionHeading(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Semantics(
            header: true,
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.palette.inkMuted))),
      );

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final height =
        math.min(760.0, MediaQuery.sizeOf(context).height * .9 - keyboard);
    return PopScope(
        canPop: !saving,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: SizedBox(
                height: math.max(180, height),
                child: Column(children: [
                  const SizedBox(height: 12),
                  const AppSheetHandle(),
                  AppFlowHeader(
                    progress: flow.progress,
                    progressLabel: 'Bike setup progress',
                    onBack: flow.step > 0 && !saving
                        ? () => go(flow.step - 1)
                        : null,
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                          controller: scroll,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          child:
                              IgnorePointer(ignoring: saving, child: page()))),
                  AppFlowFooter(
                    error: flow.error,
                    label: saving
                        ? 'Adding bike…'
                        : flow.step == flow.steps.length - 1
                            ? 'Create bike'
                            : 'Continue',
                    onPressed: saving
                        ? null
                        : flow.step == flow.steps.length - 1
                            ? create
                            : next,
                  ),
                ])),
          ),
        ));
  }
}
