import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../models/setup_test.dart';

import 'experiment_actions.dart';
import 'experiment_draft_card.dart';
import 'experiment_comparison.dart';
import 'experiment_feedback_form.dart';
import 'experiment_ride_card.dart';

class ExperimentDetailPage extends StatefulWidget {
  const ExperimentDetailPage(
      {super.key,
      required this.uid,
      required this.bike,
      required this.setup,
      required this.setupName,
      required this.initialTest,
      this.onSetupSaved,
      this.onApplied});

  final String uid, bike, setup, setupName;
  final SetupTest initialTest;
  final void Function(String, String)? onSetupSaved;
  final VoidCallback? onApplied;

  @override
  State<ExperimentDetailPage> createState() => _ExperimentDetailPageState();
}

class _ExperimentDetailPageState extends State<ExperimentDetailPage> {
  late final controller = AppDependencies.of(context).forUser(widget.uid).tests;
  late final stream = controller.watch(widget.bike, widget.setup);

  ExperimentActions get actions => ExperimentActions(
      context: context,
      controller: controller,
      uid: widget.uid,
      bike: widget.bike,
      setup: widget.setup,
      setupName: widget.setupName,
      closeOnFinish: true,
      onSetupSaved: widget.onSetupSaved,
      onApplied: widget.onApplied);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => StreamBuilder<List<SetupTest>>(
          stream: stream,
          initialData: [widget.initialTest],
          builder: (context, snapshot) {
            final stored = snapshot.data
                ?.where((test) => test.id == widget.initialTest.id)
                .firstOrNull;
            final test = stored == null
                ? null
                : controller.withSavedValues(widget.bike, widget.setup, stored);
            return Scaffold(
              appBar: buildDetailAppBar(context,
                  title: test?.name ?? widget.initialTest.name,
                  actions: test == null || test.stage == TestStage.finished
                      ? []
                      : [
                          IconButton(
                              tooltip: 'Experiment options',
                              icon: const Icon(CupertinoIcons.ellipsis),
                              onPressed: controller.isBusy
                                  ? null
                                  : () => actions.experimentOptions(test)),
                        ]),
              body: snapshot.hasError
                  ? const Center(
                      child: Text(
                          'Could not load experiments. Reopen Experiments to retry.'))
                  : !snapshot.hasData
                      ? const Center(child: AppLoadingState())
                      : test == null
                          ? const Center(
                              child: Text(
                                  'This experiment is no longer available.'))
                          : ListView(
                              padding: EdgeInsets.fromLTRB(20, 12, 20,
                                  MediaQuery.paddingOf(context).bottom + 24),
                              children: stageContent(test)),
            );
          },
        ),
      );

  List<Widget> stageContent(SetupTest test) {
    switch (test.stage) {
      case TestStage.draft:
        return [
          ExperimentDraftCard(
              test: test,
              setupName: widget.setupName,
              busy: controller.isBusy,
              showOptions: false,
              onContinue: () => actions.openDraft(test))
        ];
      case TestStage.ride:
        return [
          ExperimentComparison(
              test: test, badge: 'Ready to ride', showName: false),
          ExperimentFeedbackForm(
              key: ValueKey(test.id),
              initial: test.feedback,
              busy: controller.isBusy,
              onChanged: (feedback) {
                presentCommand(
                    context,
                    () => controller.updateFeedback(
                        widget.bike, widget.setup, test.id, feedback));
              },
              onLog: (feedback) => presentCommand(
                  context,
                  () => controller.logRide(
                      widget.bike, widget.setup, test.id, feedback))),
        ];
      case TestStage.review:
      case TestStage.finished:
        return [
          ExperimentComparison(
              test: test,
              showName: false,
              badge: test.stage == TestStage.finished
                  ? test.result
                  : '${test.rides.length} ${test.rides.length == 1 ? 'ride' : 'rides'} logged'),
          for (var i = 0; i < test.rides.length; i++)
            ExperimentRideCard(ride: test.rides[i], index: i + 1),
          if (test.stage == TestStage.review) ...[
            const SizedBox(height: 8),
            AppActionButton(
                label: 'Finish experiment',
                onPressed: controller.isBusy
                    ? null
                    : () => actions.chooseOutcome(test)),
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
                            widget.bike, widget.setup, test.id))),
          ],
        ];
    }
  }
}
