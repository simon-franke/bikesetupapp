import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../models/setup_test.dart';

import 'experiment_actions.dart';
import 'experiment_detail_page.dart';
import 'experiment_draft_card.dart';
import 'experiment_history_page.dart';

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
  late final controller = AppDependencies.of(context).forUser(widget.uid).tests;
  late final stream = controller.watch(widget.bike, widget.setup);
  bool openingNewTest = false;

  ExperimentActions get actions => ExperimentActions(
      context: context,
      controller: controller,
      uid: widget.uid,
      bike: widget.bike,
      setup: widget.setup,
      setupName: widget.setupName,
      onSetupSaved: widget.onSetupSaved,
      onApplied: widget.onApplied,
      onDraftStarted: openTest);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => StreamBuilder<List<SetupTest>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text(
                      'Could not load experiments. Reopen Experiments to retry.'));
            }

            if (!snapshot.hasData) {
              return const Center(child: AppLoadingState());
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
                if (ongoing.isNotEmpty)
                  const AppSectionLabel('Ongoing experiments'),
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
                if (previous.isNotEmpty)
                  const AppSectionLabel('Previous experiments'),
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
      Navigator.of(context).push<void>(AppRoutes.fadeSlide(ExperimentDetailPage(
          uid: widget.uid,
          bike: widget.bike,
          setup: widget.setup,
          setupName: widget.setupName,
          initialTest: test,
          onSetupSaved: widget.onSetupSaved,
          onApplied: widget.onApplied)));

  Future<void> openHistory(SetupTest test) => Navigator.of(context).push<void>(
        AppRoutes.fadeSlide(ExperimentHistoryPage(test: test)),
      );

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
      await actions.openDraft(created!);
    } finally {
      if (mounted) setState(() => openingNewTest = false);
    }
  }

  Widget testEntry([SetupTest? test]) => ExperimentDraftCard(
        test: test,
        setupName: widget.setupName,
        busy: controller.isBusy || openingNewTest,
        onContinue: test == null ? createTest : () => actions.openDraft(test),
        onRename: test == null ? null : () => actions.rename(test),
        onDiscard: test == null ? null : () => actions.finish(test),
      );
}
