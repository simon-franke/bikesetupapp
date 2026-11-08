import 'onboarding_adjuster_selector.dart';
import 'onboarding_tracking_part.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import '../../setups/ui/setting_stepper_sheet.dart';
import 'package:bikesetupapp/common/ui/app_flow.dart';
import 'package:bikesetupapp/common/ui/app_select.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../models/bike_creation_draft.dart';
import 'bike_onboarding_state.dart';
import 'frame_settings.dart';

class CreateBikeFlow extends StatefulWidget {
  const CreateBikeFlow(
      {super.key,
      required this.user,
      required this.onCreated,
      this.initialDraft,
      this.setupName = 'Default'});

  final User user;
  final BikeCreationDraft? initialDraft;
  final String setupName;
  final void Function(String, String, String, String) onCreated;

  @override
  State<CreateBikeFlow> createState() => _CreateBikeFlowState();
}

class _CreateBikeFlowState extends State<CreateBikeFlow> {
  late final flow = BikeOnboardingState(initialDraft: widget.initialDraft);
  final scroll = ScrollController();
  bool saving = false;

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

  bool acceptCurrent() => true;

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
      final result = await controllers.bikes
          .createFromDraft(reviewed, setupName: widget.setupName);
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
      widget.onCreated(reviewed.name, bikeId!, widget.setupName, setupId!);
    }
  }

  Widget field(String title, TextEditingController controller,
          {String? hint, bool number = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppFormField(
              label: title,
              child: AppTextField(
                  controller: controller,
                  hint: hint ?? 'Optional',
                  keyboardType: number
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  suffix: number ? 'mm' : null)));

  Widget travelSelector(TextEditingController controller) =>
      field('Travel', controller, hint: 'Optional', number: true);

  Widget wheel(String title, String value, ValueChanged<String> change) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppFormField(
          label: title,
          child: AppSelect<String>(
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
        ),
      );

  Widget adjuster(String label, Set<String> selected) =>
      OnboardingAdjusterSelector(
          label: label,
          selected: selected,
          onChanged: (value) => setState(() {
                selected
                  ..clear()
                  ..addAll(value);
              }));

  Widget note(String text) => AppFlowHeading(text);

  Widget optionalValue(String category, String key) {
    final value = flow.setting(category, key).text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppValueButton(
            label: key,
            value: value.isEmpty ? 'Not set' : value,
            onTap: () => showSettingStepperSheet(context,
                    uBikeID: '',
                    uSetupID: '',
                    category: category,
                    settingKey: key,
                    currentValue: value,
                    canDelete: false,
                    onClear: value.isEmpty
                        ? null
                        : () =>
                            setState(() => flow.setting(category, key).clear()),
                    saveLabel: 'Use value', onSave: (value) async {
                  setState(() => flow.setting(category, key).text = value);
                  return const CommandSuccess<void>(null);
                })),
      ]),
    );
  }

  Widget tireSettings(String tire) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        sectionHeading(tire == 'FrontTire' ? 'Front tire' : 'Rear tire'),
        optionalValue(tire, 'Pressure'),
        wheel('${tire == 'FrontTire' ? 'Front' : 'Rear'} wheel size',
            tire == 'FrontTire' ? flow.frontWheel : flow.rearWheel, (value) {
          if (tire == 'FrontTire') {
            flow.frontWheel = value;
          } else {
            flow.rearWheel = value;
          }
        }),
        const SizedBox(height: 20),
      ]);

  Widget groupedValues() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        note(flow.currentCategory),
        if (flow.currentCategory == 'Frame')
          FrameSettings(
              values: {
                for (final key in flow.currentFields)
                  key: flow.setting('Frame', key).text
              },
              onChanged: (key, value) =>
                  setState(() => flow.setting('Frame', key).text = value))
        else
          for (final key in flow.currentFields)
            optionalValue(flow.currentCategory, key),
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
              OnboardingTrackingPart('Suspension fork', '', flow.fork != 'None',
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
              OnboardingTrackingPart('Rear shock', '', flow.shock != 'None',
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
              OnboardingTrackingPart(
                  'Cockpit', 'Stem, spacers and bar position', flow.cockpit,
                  onChanged: (value) => setState(() => flow.cockpit = value)),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.border),
              OnboardingTrackingPart(
                  'Saddle', 'Height, setback and tilt', flow.saddle,
                  onChanged: (value) => setState(() => flow.saddle = value)),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.border),
              OnboardingTrackingPart(
                  'Frame', 'Flip chip and headset cups', flow.frame,
                  onChanged: (value) => setState(() => flow.frame = value)),
            ])),
      ] else if (flow.currentStep.kind == OnboardingStepKind.controls) ...[
        note(title == 'Fork'
            ? 'Match your fork’s adjusters'
            : 'Match your shock’s adjusters'),
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

  Widget sectionHeading(String title) => AppSectionLabel(title);

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
                    progressLabel:
                        'Bike setup, ${flow.step + 1} of ${flow.steps.length}',
                    onClose: saving ? null : () => Navigator.of(context).pop(),
                    closeTooltip: 'Close bike setup',
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
