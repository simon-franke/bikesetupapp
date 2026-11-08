import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'test_draft_flow.dart';
import '../controllers/tests_controller.dart';
import '../models/setup_test.dart';

import 'experiment_draft_card.dart';
import 'experiment_name_sheet.dart';

class ExperimentActions {
  const ExperimentActions(
      {required this.context,
      required this.controller,
      required this.uid,
      required this.bike,
      required this.setup,
      required this.setupName,
      this.closeOnFinish = false,
      this.onSetupSaved,
      this.onApplied,
      this.onDraftStarted});

  final BuildContext context;
  final TestsController controller;
  final String uid, bike, setup, setupName;
  final bool closeOnFinish;
  final void Function(String, String)? onSetupSaved;
  final VoidCallback? onApplied;
  final Future<void> Function(SetupTest)? onDraftStarted;

  Future<void> finish(SetupTest test,
      {bool apply = false, String? newName}) async {
    final saved = await presentCommand(
        context,
        () => controller.finish(bike, setup, test.id,
            apply: apply, newSetupName: newName));
    if (!context.mounted || !saved) return;
    if (closeOnFinish) Navigator.of(context).pop();
    if (newName != null) onSetupSaved?.call(newName, test.id);
    if (apply) onApplied?.call();
  }

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
    if (!context.mounted) return;

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
              context, () => controller.editExperiment(bike, setup, test.id))) {
        return;
      }
      if (context.mounted) {
        await openDraft(test.copyWith(stage: TestStage.draft, draftStep: 0));
      }
    }
  }

  Future<void> rename(SetupTest test) async {
    final updated = await showAppSheet<String>(
        context: context,
        builder: (_) => ExperimentNameSheet(
            initial: experimentDraftName(test, setupName),
            title: 'Experiment name',
            action: 'Done'));
    if (updated == null || !context.mounted) return;

    await presentCommand(
        context,
        () => controller.renameExperiment(
            bike, setup, test.id, test.stage, updated));
  }

  Future<void> openDraft(SetupTest test) async {
    ModalRoute<dynamic>? route;
    final started = await showAppSheet<SetupTest>(
        context: context,
        fullHeight: true,
        builder: (sheet) {
          route = ModalRoute.of(sheet);
          return TestDraftFlow(
              uid: uid,
              bike: bike,
              setup: setup,
              initial: test,
              nameFor: (test) => experimentDraftName(test, setupName));
        });
    await route?.completed;
    if (context.mounted && started != null && !closeOnFinish) {
      await onDraftStarted?.call(started);
    }
  }

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
                            value: 'Update $setupName',
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
    if (!context.mounted || outcome == null) return;

    if (outcome == 'apply') {
      await finish(test, apply: true);
    } else if (outcome == 'save') {
      final newName = await showAppSheet<String>(
          context: context,
          builder: (_) => ExperimentNameSheet(initial: test.name));
      if (newName != null && context.mounted) {
        await finish(test, newName: newName);
      }
    } else {
      await finish(test);
    }
  }
}
