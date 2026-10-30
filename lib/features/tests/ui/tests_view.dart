import 'package:flutter/material.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/features/setups/ui/setup_overview.dart';
import 'package:bikesetupapp/features/setups/ui/control_panel_grid.dart';
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
      this.onApplied});
  final String uid, bike, setup, setupName;

  final void Function(String name, String id)? onSetupSaved;
  final VoidCallback? onApplied;
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
  String part = 'Tires';
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
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => StreamBuilder<List<SetupTest>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Could not load tests. Reopen Tests to retry.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final active = snapshot.data!
                .where((t) => t.stage != TestStage.finished)
                .firstOrNull;
            if (active != null && loadedId != active.id) {
              loadedId = active.id;
              name.text = active.name;
              feeling = active.feedback.feeling;
              notes.text = active.feedback.note;
              time.text = active.feedback.time;
            }
            return ListView(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, MediaQuery.paddingOf(context).bottom + 24),
                children: [
                  if (active == null) ...[
                    SetupCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          Text('Baseline: ${widget.setupName}',
                              style:
                                  TextStyle(color: context.palette.inkMuted)),
                          const SizedBox(height: 16),
                          const Text('Test a new setup',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          const Text(
                              'Start with a copy. Change any combination of settings.'),
                          const SizedBox(height: 20),
                          action(
                              'Create test',
                              () => presentCommand(
                                  context,
                                  () => controller.create(
                                      widget.bike,
                                      widget.setup,
                                      widget.setupName,
                                      setupCategories())),
                              primary: true),
                        ])),
                    if (snapshot.data!.isNotEmpty) title('Previous tests'),
                    for (final t in snapshot.data!
                        .where((t) => t.stage == TestStage.finished)) ...[
                      comparison(t, badge: t.result),
                      for (final ride in t.rides)
                        rideCard(ride, t.rides.indexOf(ride) + 1),
                    ],
                  ] else if (active.stage == TestStage.draft)
                    ...draft(active)
                  else if (active.stage == TestStage.ride)
                    ...feedback(active)
                  else
                    ...results(active),
                ]);
          }));
  List<Widget> draft(SetupTest t) => [
        const AppFieldLabel('Test name'),
        const SizedBox(height: 12),
        AppTextField(
            controller: name,
            hint: 'Test name',
            onChanged: (_) => presentCommand(
                context,
                () => controller.renameDraft(
                    widget.bike, widget.setup, t.id, name.text))),
        const SizedBox(height: 24),
        Row(children: [
          const Expanded(child: Text('Choose settings to change')),
          Text('${t.changes.length} changed',
              style: TextStyle(color: context.palette.inkMuted))
        ]),
        const SizedBox(height: 14),
        _partTabs(t),
        const SizedBox(height: 12),
        SetupCard(
            child: Column(children: [
          for (final category in t.values.entries.where((c) => part == 'Tires'
              ? c.key.endsWith('Tire')
              : part == 'Bike fit'
                  ? c.key == 'GeneralSettings'
                  : c.key == part))
            for (final field in category.value.entries)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(part == 'Tires'
                      ? '${category.key == 'FrontTire' ? 'Front' : 'Rear'} ${field.key.toLowerCase()}'
                      : field.key),
                  subtitle: t.before[category.key]?[field.key] == field.value
                      ? null
                      : Text(
                          'Baseline ${t.before[category.key]?[field.key] ?? 'No previous value'}'),
                  trailing: Text(field.value.isEmpty ? 'Add' : field.value,
                      style: TextStyle(
                          color:
                              t.before[category.key]?[field.key] == field.value
                                  ? context.palette.ink
                                  : context.palette.accentText)),
                  onTap: controller.isBusy
                      ? null
                      : () => edit(t, category.key, field.key, field.value)),
        ])),
        Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text('The baseline stays unchanged.',
                style: TextStyle(color: context.palette.inkMuted))),
        if (t.changes.isNotEmpty)
          comparison(t, badge: '${t.changes.length} changes', showName: false),
        action(
            'Start test',
            () => presentCommand(
                context,
                () => controller.startTest(
                    widget.bike,
                    widget.setup,
                    t.id,
                    name.text.trim().isEmpty
                        ? '${widget.setupName} test'
                        : name.text)),
            primary: true,
            enabled: t.changes.isNotEmpty),
        action('Discard draft', () => finish(t)),
      ];
  Widget _partTabs(SetupTest test) {
    final parts = [
      'Tires',
      if (test.values.containsKey('Fork')) 'Fork',
      if (test.values.containsKey('Shock')) 'Shock',
      if (test.values.containsKey('Frame')) 'Frame',
      if (test.values.containsKey('Cockpit')) 'Cockpit',
      if (test.values.containsKey('Saddle')) 'Saddle',
      if (test.values.containsKey('GeneralSettings')) 'Bike fit'
    ];
    Widget tab(String p) => Semantics(
        selected: part == p,
        child: TextButton(
            style: TextButton.styleFrom(
                backgroundColor:
                    part == p ? context.palette.card : context.palette.surface2,
                foregroundColor:
                    part == p ? context.palette.cardInk : context.palette.ink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11))),
            onPressed: () => setState(() {
                  part = p;
                }),
            child: Text(p)));
    return Wrap(spacing: 6, runSpacing: 6, children: parts.map(tab).toList());
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

  List<Widget> feedback(SetupTest t) => [
        comparison(t, badge: 'Ready to ride'),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Ride feedback',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
        Row(children: [
          for (final f in ['Better', 'Same', 'Worse'])
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            backgroundColor: feeling == f
                                ? context.palette.surface2
                                : context.palette.surface,
                            side: BorderSide(
                                color: feeling == f
                                    ? context.palette.accentText
                                    : context.palette.border),
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 4)),
                        onPressed: () {
                          setState(() => feeling = f);
                          persistFeedback(t);
                        },
                        child: Text(f)))),
        ]),
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
        const Text('Optional (minutes:seconds)'),
        const SizedBox(height: 12),
        AppTextField(
            controller: time,
            hint: '03:42',
            errorText: error,
            onChanged: (_) => persistFeedback(t)),
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
  Widget rideCard(RideFeedback ride, int index) => SetupCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RIDE $index${ride.time.isEmpty ? '' : '   ${ride.time}'}',
            style: AppTextStyles.eyebrow(color: context.palette.inkMuted)),
        const SizedBox(height: 20),
        Text(ride.feeling ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        if (ride.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(ride.note)
        ],
      ]));
  List<Widget> results(SetupTest t) => [
        comparison(t, badge: '${t.rides.length} rides logged'),
        for (var i = 0; i < t.rides.length; i++) rideCard(t.rides[i], i + 1),
        action('Apply changes to baseline', () => finish(t, apply: true),
            primary: true),
        action('Save as separate setup', () async {
          final newName = await showAppSheet<String>(
              context: context, builder: (_) => _SetupName(initial: t.name));
          if (newName != null && mounted) await finish(t, newName: newName);
        }),
        action(
            'Log another ride',
            () => presentCommand(context,
                () => controller.resumeTest(widget.bike, widget.setup, t.id))),
        action('Finish without changes', () => finish(t)),
      ];
}

class _SetupName extends StatefulWidget {
  const _SetupName({required this.initial});
  final String initial;
  @override
  State<_SetupName> createState() => _SetupNameState();
}

class _SetupNameState extends State<_SetupName> {
  late final text = TextEditingController(text: widget.initial);
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
            const Text('Save as separate setup',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            AppTextField(
                controller: text,
                hint: 'Setup name',
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 20),
            AppActionButton(
                label: 'Create setup',
                onPressed: text.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, text.text.trim())),
          ]));
}
