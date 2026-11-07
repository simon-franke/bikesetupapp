import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/features/setups/ui/setup_overview.dart';
import 'package:bikesetupapp/features/setups/ui/setting_display.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import 'test_draft_flow.dart';
import 'track_time_sheet.dart';
import '../controllers/tests_controller.dart';
import '../models/setup_test.dart';

class TestsView extends StatefulWidget {
  const TestsView(
      {super.key,
      required this.uid,
      required this.bike,
      required this.setup,
      required this.setupName,
      this.onSetupSaved,
      this.onApplied,
      this.initialTest});

  final String uid, bike, setup, setupName;

  final void Function(String name, String id)? onSetupSaved;
  final VoidCallback? onApplied;
  final SetupTest? initialTest;

  @override
  State<TestsView> createState() => _TestsViewState();
}

class _TestsViewState extends State<TestsView> {
  late final TestsController controller =
      AppDependencies.of(context).forUser(widget.uid).tests;
  late final stream = controller.watch(widget.bike, widget.setup);
  final name = TextEditingController();
  final notes = TextEditingController();
  final time = TextEditingController();
  String? loadedId, feeling, error;
  bool openingNewTest = false;

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    time.dispose();
    super.dispose();
  }

  Future<void> finish(SetupTest test,
      {bool apply = false, String? newName}) async {
    final saved = await presentCommand(
        context,
        () => controller.finish(widget.bike, widget.setup, test.id,
            apply: apply, newSetupName: newName));
    if (!mounted || !saved) return;
    if (widget.initialTest != null) Navigator.of(context).pop();
    if (newName != null) widget.onSetupSaved?.call(newName, test.id);
    if (apply) widget.onApplied?.call();
  }

  Widget title(String text) => AppSectionLabel(text);

  Widget action(String text, VoidCallback run,
          {bool primary = false, bool enabled = true}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: primary
              ? AppActionButton(
                  label: text,
                  onPressed: enabled && !controller.isBusy ? run : null)
              : TextButton(
                  onPressed: enabled && !controller.isBusy ? run : null,
                  child: Text(text)));

  @override
  Widget build(BuildContext context) => content();

  Widget detail(Widget body, [SetupTest? test]) => widget.initialTest == null
      ? body
      : Scaffold(
          appBar: buildDetailAppBar(context,
              title: test?.name ?? widget.initialTest!.name,
              actions: test == null || test.stage == TestStage.finished
                  ? []
                  : [
                      IconButton(
                        tooltip: 'Experiment options',
                        icon: const Icon(CupertinoIcons.ellipsis),
                        onPressed: controller.isBusy
                            ? null
                            : () => experimentOptions(test),
                      ),
                    ]),
          body: body);

  Future<void> experimentOptions(SetupTest test) async {
    final selected =
        await showAppOptionsSheet(context: context, title: test.name, entries: [
      if (test.stage == TestStage.draft ||
          (test.stage == TestStage.ride && test.rides.isEmpty))
        const AppSheetOption(
            value: 'edit',
            label: 'Edit settings',
            icon: CupertinoIcons.slider_horizontal_3),
      const AppSheetOption(
          value: 'rename', label: 'Rename', icon: CupertinoIcons.pencil),
      const AppSheetOption(
          value: 'discard',
          label: 'Discard experiment',
          icon: CupertinoIcons.trash,
          destructive: true),
    ]);
    if (!mounted) return;

    if (selected == 'rename') {
      await rename(test);
      return;
    }

    if (selected == 'discard') {
      await finish(test);
      return;
    }

    if (selected == 'edit') {
      if (test.stage != TestStage.draft &&
          !await presentCommand(
              context,
              () => controller.editExperiment(
                  widget.bike, widget.setup, test.id))) {
        return;
      }
      if (mounted) {
        await openDraft(test.copyWith(stage: TestStage.draft, draftStep: 0));
      }
    }
  }

  Widget content() => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => StreamBuilder<List<SetupTest>>(
          stream: stream,
          initialData:
              widget.initialTest == null ? null : [widget.initialTest!],
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return detail(const Center(
                  child: Text(
                      'Could not load experiments. Reopen Experiments to retry.')));
            }

            if (!snapshot.hasData) {
              return detail(const Center(child: AppLoadingState()));
            }

            if (widget.initialTest != null) {
              return _buildExperimentDetail(snapshot.data!);
            }

            final ongoing = snapshot.data!
                .where((test) => test.stage != TestStage.finished)
                .map((test) =>
                    controller.withSavedValues(widget.bike, widget.setup, test))
                .where((test) =>
                    test.stage != TestStage.draft || test.changes.isNotEmpty)
                .toList();
            final previous = snapshot.data!
                .where((test) => test.stage == TestStage.finished);

            return ListView(
              padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 12,
                  20,
                  MediaQuery.paddingOf(context).bottom + 24),
              children: [
                if (ongoing.isEmpty) testEntry(),
                if (ongoing.isNotEmpty) title('Ongoing experiments'),
                for (final test in ongoing)
                  if (test.stage == TestStage.draft)
                    testEntry(test)
                  else
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppValueButton(
                            label: test.name,
                            value: test.stage == TestStage.ride
                                ? 'Ready to ride'
                                : 'Results',
                            onTap: () => openTest(test))),
                if (ongoing.isNotEmpty)
                  AppAddButton(
                      label: 'Create experiment',
                      onPressed: controller.isBusy || openingNewTest
                          ? null
                          : createTest),
                if (previous.isNotEmpty) title('Previous experiments'),
                for (final test in previous)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppValueButton(
                          label: test.name,
                          value: test.result.isEmpty ? 'Finished' : test.result,
                          onTap: () => openHistory(test))),
              ],
            );
          }));

  Widget _buildExperimentDetail(List<SetupTest> tests) {
    final stored =
        tests.where((test) => test.id == widget.initialTest!.id).firstOrNull;
    final active = stored == null
        ? null
        : controller.withSavedValues(widget.bike, widget.setup, stored);
    if (active != null && loadedId != active.id) {
      loadedId = active.id;
      name.text = active.name;
      feeling = active.feedback.feeling;
      notes.text = active.feedback.note;
      time.text = active.feedback.time;
    }

    return detail(
        active == null
            ? const Center(
                child: Text('This experiment is no longer available.'))
            : ListView(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, MediaQuery.paddingOf(context).bottom + 24),
                children: _experimentStageContent(active),
              ),
        active);
  }

  List<Widget> _experimentStageContent(SetupTest test) {
    switch (test.stage) {
      case TestStage.ride:
        return feedback(test);
      case TestStage.review:
        return results(test);
      case TestStage.draft:
        return [testEntry(test)];
      case TestStage.finished:
        return [
          comparison(test, badge: test.result, showName: false),
          for (var i = 0; i < test.rides.length; i++)
            rideCard(test.rides[i], i + 1),
        ];
    }
  }

  Future<void> openTest(SetupTest test) =>
      Navigator.of(context).push<void>(AppRoutes.fadeSlide(TestsView(
          uid: widget.uid,
          bike: widget.bike,
          setup: widget.setup,
          setupName: widget.setupName,
          initialTest: test,
          onSetupSaved: widget.onSetupSaved,
          onApplied: widget.onApplied)));

  Future<void> openHistory(SetupTest test) => Navigator.of(context).push<void>(
        AppRoutes.fadeSlide(Scaffold(
          appBar: buildDetailAppBar(context, title: test.name),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 12,
                20,
                MediaQuery.paddingOf(context).bottom + 24),
            children: [
              comparison(test,
                  badge: test.result.isEmpty ? 'Finished' : test.result,
                  showName: false),
              for (var i = 0; i < test.rides.length; i++)
                rideCard(test.rides[i], i + 1),
            ],
          ),
        )),
      );

  String draftName(SetupTest test) {
    if (test.name.isNotEmpty &&
        test.name != '${widget.setupName} test' &&
        test.name != '${widget.setupName} experiment') {
      return test.name;
    }

    final changes = test.changes;
    if (changes.isEmpty) return '${widget.setupName} experiment';

    if (changes
        .every((c) => c.category.endsWith('Tire') && c.field == 'Pressure')) {
      return 'Tire pressure experiment';
    }

    final categories = changes.map((c) => categoryLabel(c.category)).toSet();

    return categories.length == 1
        ? '${categories.single} experiment'
        : 'Setup experiment';
  }

  Future<void> rename(SetupTest test) async {
    final updated = await showAppSheet<String>(
        context: context,
        builder: (_) => _SetupName(
            initial: draftName(test),
            title: 'Experiment name',
            action: 'Done'));
    if (updated == null || !mounted) return;

    await presentCommand(
        context,
        () => controller.renameExperiment(
            widget.bike, widget.setup, test.id, test.stage, updated));
  }

  Future<void> openDraft(SetupTest test) async {
    ModalRoute<dynamic>? route;
    final started = await showAppSheet<SetupTest>(
        context: context,
        fullHeight: true,
        builder: (sheet) {
          route = ModalRoute.of(sheet);
          return TestDraftFlow(
              uid: widget.uid,
              bike: widget.bike,
              setup: widget.setup,
              initial: test,
              nameFor: draftName);
        });
    await route?.completed;
    if (mounted && started != null && widget.initialTest == null) {
      await openTest(started);
    }
  }

  Future<void> createTest() async {
    if (openingNewTest) return;

    setState(() => openingNewTest = true);

    try {
      SetupTest? created;
      final saved = await presentCommand(context, () async {
        final result = await controller.create(
            widget.bike, widget.setup, widget.setupName);
        if (result.isSuccess) created = result.requireValue();
        return result;
      });
      if (!saved || !mounted || created?.stage != TestStage.draft) return;
      await openDraft(created!);
    } finally {
      if (mounted) setState(() => openingNewTest = false);
    }
  }

  Widget testEntry([SetupTest? test]) {
    final changes = test?.changes ?? <TestChange>[];

    return SetupCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(test == null ? 'Try a new setup' : draftName(test),
                  style: AppTextStyles.label
                      .copyWith(color: context.palette.ink))),
          if (test != null && widget.initialTest == null)
            AppObjectMenu(
                tooltip: 'Experiment options',
                title: draftName(test),
                onRename: controller.isBusy ? null : () => rename(test),
                onDiscard: controller.isBusy ? null : () => finish(test)),
        ]),
        const SizedBox(height: 16),
        Text(
            test == null
                ? 'Tune your settings. See how it rides.'
                : '${changes.length} ${changes.length == 1 ? 'change' : 'changes'} in your draft',
            style:
                AppTextStyles.body.copyWith(color: context.palette.inkMuted)),
        if (test != null) ...[
          const SizedBox(height: 16),
          for (final change in changes.take(2))
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${categoryLabel(change.category)} ${change.field.toLowerCase()}',
                          style: AppTextStyles.body
                              .copyWith(color: context.palette.inkMuted)),
                      const SizedBox(height: 4),
                      Text('${change.before} → ${change.after}',
                          style: AppTextStyles.body
                              .copyWith(color: context.palette.playfulText)),
                    ])),
        ],
        const SizedBox(height: 24),
        SizedBox(
            width: double.infinity,
            child: AppActionButton(
                label:
                    test == null ? 'Create experiment' : 'Continue experiment',
                onPressed: controller.isBusy || openingNewTest
                    ? null
                    : test == null
                        ? createTest
                        : () => openDraft(test))),
      ]),
    );
  }

  Widget comparison(SetupTest t,
          {required String badge, bool showName = true}) =>
      SetupCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(badge,
            style: AppTextStyles.label.copyWith(color: context.palette.ink)),
        if (showName) ...[
          const SizedBox(height: 18),
          Text(t.name, style: AppTextStyles.label)
        ],
        const SizedBox(height: 24),
        comparisonValues(t),
      ]));

  Widget comparisonValues(SetupTest test) =>
      LayoutBuilder(builder: (context, constraints) {
        final p = context.palette;
        String value(TestChange change, {required bool before}) {
          final raw = before ? change.before : change.after;
          if (raw.isEmpty) return before ? 'No previous value' : 'Removed';
          return settingDisplayValue(change.field, raw,
              familyOverride: unitFamilyFromName(
                  test.fieldMetadata[change.category]?[change.field] ?? ''));
        }

        if (constraints.maxWidth < 290 ||
            MediaQuery.textScalerOf(context).scale(16) > 21) {
          Widget measurement(String label, String text,
                  {bool changed = false}) =>
              Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            AppTextStyles.caption.copyWith(color: p.inkMuted)),
                    const SizedBox(height: 4),
                    Text(text,
                        style: AppTextStyles.label
                            .copyWith(color: changed ? p.playfulText : p.ink)),
                  ]);

          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < test.changes.length; i++) ...[
                  if (i > 0) const Divider(height: 32),
                  Text(
                      '${categoryLabel(test.changes[i].category)} ${test.changes[i].field.toLowerCase()}',
                      style: AppTextStyles.body),
                  const SizedBox(height: 12),
                  Wrap(spacing: 24, runSpacing: 12, children: [
                    measurement(
                        'Baseline', value(test.changes[i], before: true)),
                    measurement('New', value(test.changes[i], before: false),
                        changed: true),
                  ]),
                ],
              ]);
        }

        return Table(
            border: TableBorder(
                horizontalInside: BorderSide(color: context.palette.border)),
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(),
              2: FlexColumnWidth()
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                Text('Setting',
                    style: AppTextStyles.caption.copyWith(color: p.inkMuted)),
                Text('Baseline',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(color: p.inkMuted)),
                Text('New',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(color: p.inkMuted))
              ]),
              for (final c in test.changes)
                TableRow(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                          '${categoryLabel(c.category)} ${c.field.toLowerCase()}')),
                  Text(value(c, before: true), textAlign: TextAlign.right),
                  Text(value(c, before: false),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: context.palette.playfulText)),
                ])
            ]);
      });

  RideFeedback get enteredFeedback =>
      RideFeedback(feeling: feeling, note: notes.text, time: time.text);

  void persistFeedback(SetupTest t) {
    presentCommand(
        context,
        () => controller.updateFeedback(
            widget.bike, widget.setup, t.id, enteredFeedback));
  }

  void selectFeeling(double value) {
    final next = RideFeedback.feelings[value.round()];
    if (feeling == next) return;
    HapticFeedback.selectionClick();
    setState(() {
      feeling = next;
      error = null;
    });
  }

  List<Widget> feedback(SetupTest t) => [
        comparison(t, badge: 'Ready to ride', showName: false),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Ride feedback', style: AppTextStyles.label)),
        Text(feeling ?? 'How did it feel?',
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
                color: feeling == null
                    ? context.palette.inkMuted
                    : context.palette.playfulText)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 16,
            trackShape: const RoundedRectSliderTrackShape(),
            thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10, elevation: 1, pressedElevation: 2),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            activeTrackColor: context.palette.playful,
            inactiveTrackColor: context.palette.surface2,
            thumbColor: context.palette.playful,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            min: 0,
            max: 4,
            divisions: 4,
            value: feeling == null
                ? 2
                : RideFeedback.feelings
                    .indexOf(feeling!)
                    .clamp(0, 4)
                    .toDouble(),
            label: feeling ?? 'Not rated',
            semanticFormatterCallback: (value) =>
                RideFeedback.feelings[value.round()],
            onChanged: selectFeeling,
            onChangeEnd: (value) {
              selectFeeling(value);
              persistFeedback(t);
            },
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Text('Much worse',
                    style: AppTextStyles.body
                        .copyWith(color: context.palette.inkMuted))),
            const SizedBox(width: 16),
            Expanded(
                child: Text('Much better',
                    textAlign: TextAlign.end,
                    style: AppTextStyles.body
                        .copyWith(color: context.palette.inkMuted))),
          ],
        ),
        const SizedBox(height: 20),
        AppFormField(
            label: 'Notes',
            child: AppTextField(
                controller: notes,
                hint: 'How did the bike feel?',
                maxLines: 3,
                onChanged: (_) => persistFeedback(t))),
        const SizedBox(height: 24),
        AppFormField(
            label: 'Track time',
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: context.palette.surface2,
                foregroundColor: context.palette.ink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                final selected = await showAppSheet<String>(
                    context: context,
                    builder: (_) => TrackTimeSheet(initial: time.text));
                if (selected == null || !mounted) return;
                setState(() {
                  time.text = selected;
                  error = null;
                });
                persistFeedback(t);
              },
              child: Row(children: [
                Expanded(
                    child: Text(
                        time.text.isEmpty ? 'Add time (optional)' : time.text)),
                const Icon(Icons.chevron_right, size: AppIconSizes.compact),
              ]),
            )),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: context.palette.red)),
          ),
        const SizedBox(height: 18),
        action('Log ride', () async {
          final feedback = enteredFeedback;
          if (feedback.validationError != null) {
            setState(() => error = feedback.validationError);
            return;
          }

          if (await presentCommand(
              context,
              () => controller.logRide(
                  widget.bike, widget.setup, t.id, feedback))) {
            if (!mounted) return;
            setState(() {
              feeling = null;
              error = null;
              notes.clear();
              time.clear();
            });
          }
        }, primary: true),
      ];

  Future<void> chooseOutcome(SetupTest test) async {
    ModalRoute<dynamic>? sheetRoute;
    final outcome = await showAppSheet<String>(
        context: context,
        builder: (sheet) {
          sheetRoute = ModalRoute.of(sheet);

          return SafeArea(
              top: false,
              child: Padding(
                  padding: appSheetPadding(sheet),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppSheetHeader(title: 'Choose an outcome'),
                        AppValueButton(
                            label: 'Use tested settings',
                            value: 'Update ${widget.setupName}',
                            icon: CupertinoIcons.check_mark,
                            onTap: () => Navigator.pop(sheet, 'apply')),
                        const SizedBox(height: 8),
                        AppValueButton(
                            label: 'Save as new setup',
                            icon: CupertinoIcons.plus,
                            onTap: () => Navigator.pop(sheet, 'save')),
                        const SizedBox(height: 8),
                        AppValueButton(
                            label: 'Keep current settings',
                            icon: CupertinoIcons.arrow_uturn_left,
                            onTap: () => Navigator.pop(sheet, 'keep')),
                      ])));
        });
    await sheetRoute?.completed;
    if (!mounted || outcome == null) return;

    if (outcome == 'apply') {
      await finish(test, apply: true);
    } else if (outcome == 'save') {
      final newName = await showAppSheet<String>(
          context: context, builder: (_) => _SetupName(initial: test.name));
      if (newName != null && mounted) await finish(test, newName: newName);
    } else {
      await finish(test);
    }
  }

  Widget rideCard(RideFeedback ride, int index) {
    final p = context.palette;

    return SetupCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 20,
          runSpacing: 8,
          children: [
            Text('Ride $index',
                style: AppTextStyles.body.copyWith(color: p.inkMuted)),
            if (ride.time.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(CupertinoIcons.stopwatch,
                    size: AppIconSizes.compact, color: p.inkMuted),
                const SizedBox(width: 6),
                Text(ride.time,
                    style: AppTextStyles.body.copyWith(color: p.inkMuted)),
              ]),
          ]),
      if (ride.feeling != null) ...[
        const SizedBox(height: 14),
        Text(ride.feeling!,
            style: AppTextStyles.heading.copyWith(color: p.ink)),
      ],
      if (ride.note.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(ride.note, style: AppTextStyles.body.copyWith(color: p.inkMuted)),
      ],
    ]));
  }

  List<Widget> results(SetupTest t) => [
        comparison(t,
            badge:
                '${t.rides.length} ${t.rides.length == 1 ? 'ride' : 'rides'} logged',
            showName: false),
        for (var i = 0; i < t.rides.length; i++) rideCard(t.rides[i], i + 1),
        const SizedBox(height: 8),
        AppActionButton(
            label: 'Finish experiment',
            onPressed: controller.isBusy ? null : () => chooseOutcome(t)),
        const SizedBox(height: 10),
        AppActionButton(
            label: 'Log another ride',
            outlined: true,
            icon: CupertinoIcons.plus,
            onPressed: controller.isBusy
                ? null
                : () => presentCommand(
                    context,
                    () => controller.resumeTest(
                        widget.bike, widget.setup, t.id))),
      ];
}

class _SetupName extends StatefulWidget {
  const _SetupName(
      {required this.initial,
      this.title = 'Save as new setup',
      this.action = 'Create setup'});

  final String initial, title, action;

  @override
  State<_SetupName> createState() => _SetupNameState();
}

class _SetupNameState extends State<_SetupName> {
  late final text = TextEditingController(text: widget.initial)
    ..selection =
        TextSelection(baseOffset: 0, extentOffset: widget.initial.length);

  void submit() {
    if (text.text.trim().isNotEmpty) {
      Navigator.pop(context, text.text.trim());
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: appSheetPadding(context),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(title: widget.title),
            AppTextField(
                controller: text,
                hint:
                    widget.action == 'Done' ? 'Experiment name' : 'Setup name',
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 24),
            AppActionButton(
                label: widget.action,
                onPressed: text.text.trim().isEmpty ? null : submit),
          ]));
}
