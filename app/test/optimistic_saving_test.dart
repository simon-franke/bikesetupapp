import 'dart:async';

import 'package:bikesetupapp/common/controllers/optimistic_edits.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/controllers/setups_controller.dart';
import 'package:bikesetupapp/features/setups/ui/control_panel_grid.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_repositories.dart';
import 'support/fake_tests_repository.dart';
import 'package:bikesetupapp/features/tests/controllers/tests_controller.dart';
import 'package:bikesetupapp/features/tests/models/setup_test.dart';

class DelayedDraft extends MemoryTests {
  final gate = Completer<void>();

  @override
  Future<void> update(String bike, String setup, String id,
      {required TestStage expectedStage,
      required SetupTest Function(SetupTest) change}) async {
    await gate.future;
    return super
        .update(bike, setup, id, expectedStage: expectedStage, change: change);
  }
}

class DelayedSettings extends FakeSetupsRepository {
  final pending = <Completer<void>>[];

  @override
  Stream<Map<String, dynamic>> getSettings(
          String bike, String category, String setup) =>
      Stream.value({'Pressure': '24 psi'});

  @override
  Future<void> setSetting(
      String key, String value, String bike, String category, String setup) {
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  test('reviewing an older edit rolls back to the newest committed value',
      () async {
    final draft = SetupTest(
        setupInformation: const {},
        id: 't',
        name: 'Test',
        before: {
          'Fork': {'Pressure': '24 psi'}
        },
        values: {
          'Fork': {'Pressure': '24 psi'}
        });
    final repo = MemoryTests()..records['t'] = draft;
    final controller = TestsController(repo, FakeSetupsRepository());
    await controller.updateField('b', 's', 't', 'Fork', 'Pressure', '30 psi',
        previousValue: '24 psi');
    controller.withSavedValues('b', 's', repo.records['t']!);
    repo.fail = true;
    await controller.updateField('b', 's', 't', 'Fork', 'Pressure', '28 psi',
        previousValue: '24 psi');
    expect(
        controller
            .withSavedValues('b', 's', repo.records['t']!)
            .values['Fork']!['Pressure'],
        '30 psi');
    controller.dispose();
    await repo.updates.close();
  });

  test('draft is optimistic while pending and rolls back on failure', () async {
    final draft = SetupTest(
        setupInformation: const {},
        id: 't',
        name: 'Test',
        before: {
          'Fork': {'Pressure': '24 psi'}
        },
        values: {
          'Fork': {'Pressure': '24 psi'}
        });
    final repo = DelayedDraft()..records['t'] = draft;
    final controller = TestsController(repo, FakeSetupsRepository());
    final save = controller.updateField(
        'b', 's', 't', 'Fork', 'Pressure', '28 psi',
        previousValue: '24 psi');
    expect(
        controller.withSavedValues('b', 's', draft).values['Fork']!['Pressure'],
        '28 psi');
    repo.fail = true;
    repo.gate.complete();
    expect((await save).isSuccess, false);
    expect(
        controller.withSavedValues('b', 's', draft).values['Fork']!['Pressure'],
        '24 psi');
    controller.dispose();
    await repo.updates.close();
  });

  test('an older failure preserves newer edits and rollback uses last success',
      () {
    final edits = OptimisticEdits<String, String>();
    final first = edits.begin('pressure', '24', '26');
    final second = edits.begin('pressure', '26', '28');
    edits.complete('pressure', first, success: true);
    expect(edits.resolve('pressure', '24'), '28');
    edits.complete('pressure', second, success: false);
    expect(edits.resolve('pressure', '24'), '26');
    expect(edits.resolve('pressure', '26'), '26');
    expect(edits.resolve('pressure', '30'), '30');
  });

  test('setup stream immediately publishes edits and restores failed saves',
      () async {
    final repo = DelayedSettings();
    final controller = SetupsController(repo);
    final seen = <String>[];
    final subscription = controller
        .getSettings('b', 'Fork', 's')
        .listen((values) => seen.add(values['Pressure'] as String));
    await Future<void>.delayed(Duration.zero);
    final first = controller.setSetting('Pressure', '26 psi', 'b', 'Fork', 's');
    final second =
        controller.setSetting('Pressure', '28 psi', 'b', 'Fork', 's');
    await Future<void>.delayed(Duration.zero);
    expect(seen.last, '28 psi');
    repo.pending.first.completeError(const AppFailure(FailureCode.saveFailed));
    expect((await first).isSuccess, false);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last, '28 psi');
    repo.pending.last.completeError(const AppFailure(FailureCode.saveFailed));
    expect((await second).isSuccess, false);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last, '24 psi');
    await subscription.cancel();
    controller.dispose();
  });

  testWidgets(
      'editor closes before saving and Review recovers the attempted value',
      (tester) async {
    final completion = Completer<CommandResult<void>>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    child: const Text('Edit'),
                    onPressed: () => showSettingStepperSheet(context,
                        uBikeID: 'b',
                        category: 'Fork',
                        uSetupID: 's',
                        settingKey: 'Pressure',
                        currentValue: '24 psi',
                        canDelete: false,
                        saveLabel: 'Save',
                        optimistic: true,
                        onSave: (_) => completion.future),
                  ))),
    ));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    tester
        .widget<SettingValueEditor>(find.byType(SettingValueEditor))
        .onChanged(28);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingValueEditor), findsNothing);
    completion
        .complete(const CommandFailure(AppFailure(FailureCode.saveFailed)));
    await tester.pumpAndSettle();
    expect(find.textContaining('28 psi wasn’t saved'), findsOneWidget);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingValueEditor), findsOneWidget);
    expect(
        tester
            .widget<SettingValueEditor>(find.byType(SettingValueEditor))
            .initialValue,
        28);
  });
}
