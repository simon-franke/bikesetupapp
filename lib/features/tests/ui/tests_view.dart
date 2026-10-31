import 'package:bikesetupapp/common/ui/bike_icon.dart';
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

  Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Text(text,
          style: AppTextStyles.inter(
              size: 28,
              weight: FontWeight.w700,
              color: context.palette.ink,
              letterSpacing: -1)));
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
  Widget build(BuildContext context) => widget.initialTest == null
      ? content()
      : Scaffold(
          appBar: AppBar(title: Text(widget.initialTest!.name)),
          body: content());

  Widget content() => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => StreamBuilder<List<SetupTest>>(
          stream: stream,
          initialData:
              widget.initialTest == null ? null : [widget.initialTest!],
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Could not load tests. Reopen Tests to retry.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (widget.initialTest != null) {
              final stored = snapshot.data!
                  .where((test) => test.id == widget.initialTest!.id)
                  .firstOrNull;
              final active = stored == null
                  ? null
                  : controller.withSavedValues(
                      widget.bike, widget.setup, stored);
              if (active != null && loadedId != active.id) {
                loadedId = active.id;
                name.text = active.name;
                feeling = active.feedback.feeling;
                notes.text = active.feedback.note;
                time.text = active.feedback.time;
              }
              return active == null
                  ? const Center(
                      child: Text('This test is no longer available.'))
                  : ListView(
                      padding: EdgeInsets.fromLTRB(20, 12, 20,
                          MediaQuery.paddingOf(context).bottom + 24),
                      children: active.stage == TestStage.ride
                          ? feedback(active)
                          : active.stage == TestStage.review
                              ? results(active)
                              : active.stage == TestStage.draft
                                  ? [testEntry(active)]
                                  : [
                                      comparison(active,
                                          badge: active.result,
                                          showName: false),
                                      for (var i = 0;
                                          i < active.rides.length;
                                          i++)
                                        rideCard(active.rides[i], i + 1)
                                    ],
                    );
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
                testEntry(),
                if (ongoing.isNotEmpty) title('Ongoing tests'),
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
                if (previous.isNotEmpty) title('Previous tests'),
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
          appBar: AppBar(
            leading: const BackButton(),
            title: Text(test.name),
          ),
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
    if (test.name.isNotEmpty && test.name != '${widget.setupName} test') {
      return test.name;
    }
    final changes = test.changes;
    if (changes.isEmpty) return '${widget.setupName} test';
    if (changes
        .every((c) => c.category.endsWith('Tire') && c.field == 'Pressure')) {
      return 'Tire pressure test';
    }
    final categories = changes.map((c) => categoryLabel(c.category)).toSet();
    return categories.length == 1 ? '${categories.single} test' : 'Setup test';
  }

  Future<void> rename(SetupTest test) async {
    final updated = await showAppSheet<String>(
        context: context,
        builder: (_) => _SetupName(
            initial: draftName(test), title: 'Test name', action: 'Done'));
    if (updated == null || !mounted) return;
    await presentCommand(
        context,
        () => controller.renameDraft(
            widget.bike, widget.setup, test.id, updated));
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
    if (mounted && started != null) await openTest(started);
  }

  Future<void> createTest() async {
    if (openingNewTest) return;
    setState(() => openingNewTest = true);
    try {
      SetupTest? created;
      final saved = await presentCommand(context, () async {
        final result = await controller.create(
            widget.bike, widget.setup, widget.setupName, setupCategories());
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
          BikeIcon(size: 40, color: context.palette.accentText),
          const SizedBox(width: 14),
          Expanded(
              child: Text(test == null ? 'Try a new setup' : draftName(test),
                  style: AppTextStyles.inter(
                      size: 22,
                      weight: FontWeight.w600,
                      color: context.palette.ink))),
          if (test != null)
            AppObjectMenu(
                tooltip: 'Test options',
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
                AppTextStyles.inter(size: 16, color: context.palette.inkMuted)),
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
                          style: AppTextStyles.inter(
                              size: 14, color: context.palette.inkMuted)),
                      const SizedBox(height: 4),
                      Text('${change.before} → ${change.after}',
                          style: AppTextStyles.inter(
                              size: 16, color: context.palette.accentText)),
                    ])),
        ],
        const SizedBox(height: 24),
        SizedBox(
            width: double.infinity,
            child: AppActionButton(
                label: test == null ? 'Create test' : 'Continue test',
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
            style: TextStyle(
                color: context.palette.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        if (showName) ...[
          const SizedBox(height: 18),
          Text(t.name,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600))
        ],
        const SizedBox(height: 24),
        Table(
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
                const Text('Setting'),
                const Text('Baseline', textAlign: TextAlign.right),
                const Text('Test', textAlign: TextAlign.right)
              ]),
              for (final c in t.changes)
                TableRow(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                          '${categoryLabel(c.category)} ${c.field.toLowerCase()}')),
                  Text(c.before.isEmpty ? 'No previous value' : c.before,
                      textAlign: TextAlign.right),
                  Text(c.after.isEmpty ? 'Removed' : c.after,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: context.palette.accentText)),
                ])
            ]),
      ]));
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
            child: Text('Ride feedback',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
        Text(feeling ?? 'How did it feel?',
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(
                size: 18,
                weight: FontWeight.w600,
                color: feeling == null
                    ? context.palette.inkMuted
                    : context.palette.accentText)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 16,
            trackShape: const RoundedRectSliderTrackShape(),
            thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10, elevation: 1, pressedElevation: 2),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            activeTrackColor: context.palette.accent,
            inactiveTrackColor: context.palette.surface2,
            thumbColor: context.palette.accent,
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
                    style: AppTextStyles.inter(
                        size: 14, color: context.palette.inkMuted))),
            const SizedBox(width: 16),
            Expanded(
                child: Text('Much better',
                    textAlign: TextAlign.end,
                    style: AppTextStyles.inter(
                        size: 14, color: context.palette.inkMuted))),
          ],
        ),
        const SizedBox(height: 20),
        const AppFieldLabel('Notes'),
        const SizedBox(height: 12),
        AppTextField(
            controller: notes,
            hint: 'How did the bike feel?',
            maxLines: 3,
            onChanged: (_) => persistFeedback(t)),
        const SizedBox(height: 24),
        const AppFieldLabel('Track time'),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: context.palette.surface2,
            foregroundColor: context.palette.ink,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            const Icon(Icons.chevron_right, size: 20),
          ]),
        ),
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
        action('Discard test', () => finish(t)),
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
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppSheetHandle(),
                        const SizedBox(height: 24),
                        Text('Finish test',
                            style: AppTextStyles.inter(
                                size: 24,
                                weight: FontWeight.w600,
                                color: sheet.palette.ink)),
                        const SizedBox(height: 20),
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
                style: AppTextStyles.inter(size: 14, color: p.inkMuted)),
            if (ride.time.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(CupertinoIcons.stopwatch, size: 16, color: p.inkMuted),
                const SizedBox(width: 6),
                Text(ride.time,
                    style: AppTextStyles.mono(
                        size: 14, weight: FontWeight.w500, color: p.inkMuted)),
              ]),
          ]),
      if (ride.feeling != null) ...[
        const SizedBox(height: 14),
        Text(ride.feeling!,
            style: AppTextStyles.inter(
                size: 20, weight: FontWeight.w600, color: p.ink)),
      ],
      if (ride.note.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(ride.note,
            style:
                AppTextStyles.inter(size: 16, color: p.inkMuted, height: 1.4)),
      ],
    ]));
  }

  List<Widget> results(SetupTest t) => [
        comparison(t, badge: '${t.rides.length} rides logged', showName: false),
        for (var i = 0; i < t.rides.length; i++) rideCard(t.rides[i], i + 1),
        const SizedBox(height: 8),
        AppActionButton(
            label: 'Finish test',
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
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSheetHandle(),
            const SizedBox(height: 24),
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            AppTextField(
                controller: text,
                hint: widget.action == 'Done' ? 'Test name' : 'Setup name',
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 20),
            AppActionButton(
                label: widget.action,
                onPressed: text.text.trim().isEmpty ? null : submit),
          ]));
}
