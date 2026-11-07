import '../../setups/ui/add_field_bottom_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import '../../setups/ui/field_meta.dart';
import '../../setups/models/unit_system.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_flow.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/features/setups/ui/control_panel_grid.dart';
import '../controllers/tests_controller.dart';
import '../models/setup_test.dart';

class TestDraftFlow extends StatefulWidget {
  const TestDraftFlow(
      {super.key,
      required this.uid,
      required this.bike,
      required this.setup,
      required this.initial,
      required this.nameFor});

  final String uid, bike, setup;
  final SetupTest initial;
  final String Function(SetupTest) nameFor;

  @override
  State<TestDraftFlow> createState() => _TestDraftFlowState();
}

class _TestDraftFlowState extends State<TestDraftFlow> {
  late final TestsController controller =
      AppDependencies.of(context).forUser(widget.uid).tests;
  late final stream = controller.watch(widget.bike, widget.setup);
  bool receivedLiveDraft = false;
  bool canExit = false, closing = false;
  SetupTest? lastVisibleDraft;

  Future<void> close() async {
    if (closing) return;

    closing = true;
    final saved = await presentCommand(
        context,
        () => controller.discardUnchangedDraft(
            widget.bike, widget.setup, widget.initial.id));
    if (!mounted) return;

    if (!saved) closing = false;

    if (saved) {
      setState(() => canExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  static const groups = {
    'Tires': ['FrontTire', 'RearTire'],
    'Fork': ['Fork'],
    'Shock': ['Shock'],
    'Frame': ['Frame'],
    'Cockpit': ['Cockpit'],
    'Saddle': ['Saddle'],
    'Bike fit': ['GeneralSettings'],
  };

  Map<String, List<String>> groupsFor(SetupTest test) => {
        ...groups,
        for (final category in test.values.keys)
          if (!groups.values.any((keys) => keys.contains(category)))
            category: [category],
      };

  Future<void> move(SetupTest test, int step) async {
    await presentCommand(
        context,
        () =>
            controller.moveDraftStep(widget.bike, widget.setup, test.id, step));
  }

  Future<void> start(SetupTest test) async {
    final saved = await presentCommand(
        context,
        () => controller.startTest(
            widget.bike, widget.setup, test.id, widget.nameFor(test)));
    if (saved && mounted) {
      setState(() => canExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(
              test.copyWith(name: widget.nameFor(test), stage: TestStage.ride));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: canExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: Scaffold(
        backgroundColor: context.palette.surface,
        body: SafeArea(
            child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => StreamBuilder<List<SetupTest>>(
            stream: stream,
            initialData: [widget.initial],
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return unavailable(
                    'Could not load your draft. Close and try again.');
              }

              final liveTest = snapshot.data
                  ?.where((test) => test.id == widget.initial.id)
                  .firstOrNull;
              if (liveTest != null &&
                  snapshot.connectionState == ConnectionState.active) {
                receivedLiveDraft = true;
              }

              final snapshotTest = closing
                  ? lastVisibleDraft ?? widget.initial
                  : liveTest ?? (!receivedLiveDraft ? widget.initial : null);
              final test = snapshotTest == null
                  ? null
                  : controller.withSavedValues(
                      widget.bike, widget.setup, snapshotTest);
              if (test == null || test.stage != TestStage.draft) {
                return unavailable('This draft is no longer available.');
              }

              lastVisibleDraft = test;
              final available = groupsFor(test)
                  .entries
                  .where((group) => group.value.any(
                      (category) => test.values[category]?.isNotEmpty ?? false))
                  .toList();
              final step = test.draftStep
                  .clamp(0, available.isEmpty ? 0 : available.length - 1);
              final group = available.isEmpty ? null : available[step];
              final last = step == available.length - 1;
              final changed = group != null &&
                  test.changes
                      .any((change) => group.value.contains(change.category));

              return Column(children: [
                AppFlowHeader(
                  progress:
                      available.isEmpty ? 0 : (step + 1) / available.length,
                  progressLabel:
                      'Experiment setup, ${step + 1} of ${available.length}',
                  onClose: close,
                  closeTooltip: 'Close experiment',
                  onBack: controller.isBusy || step == 0
                      ? null
                      : () => move(test, step - 1),
                ),
                Expanded(
                    child: ListView(
                  key: ValueKey(step),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    AppFlowHeading(group == null
                        ? 'No settings yet'
                        : 'What would you like to change?'),
                    if (group != null) ...[
                      Text(group.key,
                          style: AppTextStyles.body
                              .copyWith(color: context.palette.inkMuted)),
                      const SizedBox(height: 24),
                    ],
                    if (group != null) panel(test, group.value),
                    if (last && test.changes.isEmpty)
                      Text('Adjust a setting to start an experiment.',
                          style: AppTextStyles.body
                              .copyWith(color: context.palette.inkMuted)),
                  ],
                )),
                AppFlowFooter(
                  label: last
                      ? 'Start experiment'
                      : changed
                          ? 'Use these changes'
                          : 'Keep these settings',
                  onPressed: controller.isBusy ||
                          group == null ||
                          (last && test.changes.isEmpty)
                      ? null
                      : () => last ? start(test) : move(test, step + 1),
                ),
              ]);
            },
          ),
        )),
      ));

  Widget unavailable(String message) => Column(children: [
        AppFlowHeader(
            progress: 0,
            progressLabel: 'Experiment setup',
            onClose: close,
            closeTooltip: 'Close experiment'),
        Expanded(
            child: Center(
                child: Padding(
                    padding: const EdgeInsets.all(20), child: Text(message)))),
      ]);

  Widget panel(SetupTest test, List<String> categories) => Padding(
        padding: EdgeInsets.zero,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final category in categories) ...[
            if (category != categories.first) const SizedBox(height: 16),
            for (final field
                in (test.values[category] ?? <String, String>{}).entries)
              if (field.value.trim().isNotEmpty)
                draftField(test, category, field.key, field.value),
            AppAddButton(
                label: categories.length > 1
                    ? 'Add ${category == 'FrontTire' ? 'front' : 'rear'} setting'
                    : 'Add setting',
                onPressed: controller.isBusy
                    ? null
                    : () => addSetting(test, category)),
          ],
        ]),
      );

  Future<void> addSetting(SetupTest test, String category) =>
      showAddDraftFieldSheet(context,
          bike: widget.bike,
          setup: widget.setup,
          category: category,
          existingValues: test.values[category] ?? {},
          onSave: (field, value, family) => controller.addField(
              widget.bike, widget.setup, test.id, category, field, value,
              family: family));

  String fieldLabel(String category, String field) => category.endsWith('Tire')
      ? '${category == 'FrontTire' ? 'Front' : 'Rear'} ${field.toLowerCase()}'
      : field;

  Widget draftField(
      SetupTest test, String category, String field, String value) {
    final before = test.before[category]?[field];
    final changed = !sameSettingValue(before, value);
    final meta = kFieldMeta[field];
    String display(String raw) => SettingValue.parse(raw,
            fallbackFamily: unitFamilyFromName(
                    test.fieldMetadata[category]?[field] ?? '') ??
                meta?.family,
            fallbackUnit: meta?.defaultUnit)
        .format();
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextButton(
        style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            backgroundColor: p.bg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            foregroundColor: p.ink),
        onPressed: () => edit(test, category, field, value),
        child: SizedBox(
            width: double.infinity,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fieldLabel(category, field),
                  style: AppTextStyles.caption.copyWith(color: p.inkMuted)),
              const SizedBox(height: 6),
              Text.rich(TextSpan(children: [
                if (changed && before?.isNotEmpty == true && before != '--')
                  TextSpan(
                      text: '${display(before!)} → ',
                      style: AppTextStyles.body.copyWith(color: p.inkMuted)),
                TextSpan(
                    text: display(value),
                    style: AppTextStyles.label
                        .copyWith(color: changed ? p.accentText : p.ink)),
              ])),
            ])),
      ),
    );
  }

  Future<void> edit(
      SetupTest t, String category, String field, String value) async {
    await showSettingStepperSheet(context,
        uBikeID: widget.bike,
        category: category,
        uSetupID: widget.setup,
        settingKey: field,
        currentValue: value,
        familyOverride:
            unitFamilyFromName(t.fieldMetadata[category]?[field] ?? ''),
        canDelete: false,
        optimistic: true,
        saveLabel: 'Save to experiment', onSave: (v) {
      return controller.updateField(
          widget.bike, widget.setup, t.id, category, field, v,
          previousValue: value);
    });
  }
}
