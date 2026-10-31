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
              final step = test.draftStep.clamp(0, available.length);
              final review = step == available.length;
              final group = review ? null : available[step];
              final changed = group != null &&
                  test.changes
                      .any((change) => group.value.contains(change.category));
              return Column(children: [
                AppFlowHeader(
                  progress: (step + 1) / (available.length + 1),
                  progressLabel: review
                      ? 'Review test changes'
                      : 'Test setup, ${step + 1} of ${available.length}',
                  onClose: close,
                  closeTooltip: 'Close test',
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
                    AppFlowHeading(review ? 'Ready to try it?' : group!.key),
                    if (!review)
                      panel(test, group!.value)
                    else if (test.changes.isEmpty)
                      const Text(
                          'Nothing changed yet. Go back and adjust a setting to start a test.')
                    else
                      overview(test),
                  ],
                )),
                AppFlowFooter(
                  label: review
                      ? 'Start test'
                      : changed
                          ? 'Continue'
                          : 'Leave as is',
                  onPressed:
                      controller.isBusy || (review && test.changes.isEmpty)
                          ? null
                          : () => review ? start(test) : move(test, step + 1),
                ),
              ]);
            },
          ),
        )),
      ));

  Widget unavailable(String message) => Column(children: [
        AppFlowHeader(
            progress: 0,
            progressLabel: 'Test setup',
            onClose: close,
            closeTooltip: 'Close test'),
        Expanded(
            child: Center(
                child: Padding(
                    padding: const EdgeInsets.all(20), child: Text(message)))),
      ]);

  Widget overview(SetupTest test) {
    final p = context.palette;
    final summaryStyle =
        AppTextStyles.inter(size: 16, color: p.ink).copyWith(height: 1.4);
    final changes = test.changes;
    final sections = groupsFor(test).entries.where((group) =>
        changes.any((change) => group.value.contains(change.category)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in sections) ...[
          Semantics(
            header: true,
            child: Text(group.key,
                style: summaryStyle.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 4),
          for (final change in group.value.expand((category) =>
              changes.where((change) => change.category == category)))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fieldLabel(change.category, change.field),
                      style: summaryStyle.copyWith(color: p.inkMuted)),
                  const SizedBox(height: 4),
                  Text.rich(TextSpan(children: [
                    if (change.before.isNotEmpty && change.before != '--')
                      TextSpan(
                        text: '${change.before} → ',
                        style: summaryStyle.copyWith(color: p.inkDim),
                      ),
                    TextSpan(
                      text: change.after,
                      style: summaryStyle.copyWith(
                          fontWeight: FontWeight.w600, color: p.accentText),
                    ),
                  ])),
                ],
              ),
            ),
          if (group.key != sections.last.key) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 20),
          ],
        ],
      ],
    );
  }

  Widget panel(SetupTest test, List<String> categories) {
    final fields = [
      for (final category in categories)
        for (final field
            in (test.values[category] ?? <String, String>{}).entries)
          (category, field.key, field.value),
    ];
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(builder: (context, constraints) {
          final paired = constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(14) <= 20;
          final width =
              paired ? (constraints.maxWidth - 8) / 2 : constraints.maxWidth;
          final labelStyle = AppTextStyles.inter(
                  size: 14,
                  weight: FontWeight.w400,
                  color: context.palette.inkMuted)
              .copyWith(height: 1.3);
          var labelHeight = 0.0;
          for (final field in fields) {
            final painter = TextPainter(
              text: TextSpan(
                  text: fieldLabel(field.$1, field.$2), style: labelStyle),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: width - 24 - 8 - 18);
            if (painter.height > labelHeight) labelHeight = painter.height;
            painter.dispose();
          }
          final columns = paired ? 2 : 1;
          return Column(children: [
            for (var i = 0; i < fields.length; i += columns) ...[
              if (i > 0) const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < columns; j++) ...[
                      if (j > 0) const SizedBox(width: 8),
                      Expanded(
                        child: i + j < fields.length
                            ? draftField(test, fields[i + j].$1,
                                fields[i + j].$2, fields[i + j].$3,
                                labelHeight: labelHeight,
                                labelStyle: labelStyle)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ]);
        }),
      ),
    );
  }

  String fieldLabel(String category, String field) => category.endsWith('Tire')
      ? '${category == 'FrontTire' ? 'Front' : 'Rear'} ${field.toLowerCase()}'
      : field;

  Widget draftField(SetupTest test, String category, String field, String value,
      {required double labelHeight, required TextStyle labelStyle}) {
    final before = test.before[category]?[field];
    final changed = !sameSettingValue(before, value);
    final label = fieldLabel(category, field);
    final numeric = RegExp(r'^(-?\d+(?:[.,]\d+)?)\s*(.*)$').firstMatch(value);
    final p = context.palette;
    final color = changed ? p.accentText : p.ink;
    return TextButton(
      style: TextButton.styleFrom(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.all(12),
        foregroundColor: p.ink,
        backgroundColor: p.bg,
        side: BorderSide(color: changed ? p.accentText : p.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ).copyWith(splashFactory: NoSplash.splashFactory),
      onPressed:
          controller.isBusy ? null : () => edit(test, category, field, value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: labelHeight,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(label, style: labelStyle)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 18, color: p.inkMuted),
              ])),
          const SizedBox(height: 16),
          if (numeric != null)
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: numeric.group(1),
                  style: AppTextStyles.inter(
                      size: 36,
                      weight: FontWeight.w600,
                      color: color,
                      letterSpacing: -1)),
              if (numeric.group(2)!.isNotEmpty)
                TextSpan(
                    text: ' ${numeric.group(2)}',
                    style: AppTextStyles.inter(
                        size: 14, weight: FontWeight.w400, color: color)),
            ]))
          else
            Text(value.isEmpty ? 'Add' : value,
                style: AppTextStyles.inter(size: 22, color: color)),
          const SizedBox(height: 10),
          Text(
              changed
                  ? (before != null && before.isNotEmpty
                      ? 'from $before'
                      : 'Added')
                  : ' ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: p.inkMuted)),
        ],
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
        isDefault: true, onSave: (v) {
      return controller.updateField(
          widget.bike, widget.setup, t.id, category, field, v);
    });
  }
}
