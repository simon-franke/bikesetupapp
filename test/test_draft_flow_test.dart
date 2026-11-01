import 'dart:async';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/features/tests/controllers/tests_controller.dart';
import 'package:bikesetupapp/features/tests/models/setup_test.dart';
import 'package:bikesetupapp/features/tests/ui/test_draft_flow.dart';
import 'package:bikesetupapp/features/tests/ui/tests_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_repositories.dart';
import 'support/fake_tests_repository.dart';

void main() {
  for (final size in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets(
        'draft cards align with wrapped labels at ${size.$1}/${size.$2}',
        (tester) async {
      tester.view.physicalSize = Size(size.$1, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final before = {
        'Low Speed Compression': '1 clicks',
        'High Speed Rebound': '1 clicks',
        'Pressure': '84 psi',
        'Low Speed Rebound': '1 clicks',
        'Tokens': '6 count',
        'High Speed Compression': '5 clicks',
      };
      final draft = testExperiment(id: 'test', name: 'Test', before: {
        'Fork': before
      }, values: {
        'Fork': {
          ...before,
          'Low Speed Compression': '4 clicks',
          'Low Speed Rebound': '3 clicks'
        }
      });
      final repo = MemoryTests()..records['test'] = draft;
      final deps = AppDependencies(
          testsRepository: (_) => repo,
          setupsRepository: (_) => FakeSetupsRepository());
      await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(size.$2)),
              child: child!),
          home: TestDraftFlow(
              uid: 'user',
              bike: 'bike',
              setup: 'setup',
              initial: draft,
              nameFor: (test) => test.name),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('High Speed Compression'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('High Speed Compression'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      deps.dispose();
      await repo.updates.close();
    });
  }

  test(
      'saved values survive stale snapshots, preserve other fields and release on acknowledgement',
      () async {
    final original = testExperiment(id: 'test', name: 'Test', before: {
      'FrontTire': {'Pressure': '22 psi'},
      'RearTire': {'Pressure': '25 psi'},
    }, values: {
      'FrontTire': {'Pressure': '22 psi'},
      'RearTire': {'Pressure': '25 psi'},
    });
    final repo = MemoryTests()..records['test'] = original;
    final controller = TestsController(repo, FakeSetupsRepository());
    await controller.updateField(
        'bike', 'setup', 'test', 'FrontTire', 'Pressure', '24 psi');
    final unrelated = original.copyWith(values: {
      'FrontTire': {'Pressure': '22 psi'},
      'RearTire': {'Pressure': '27 psi'},
    });
    final merged = controller.withSavedValues('bike', 'setup', unrelated);
    expect(merged.values['FrontTire']!['Pressure'], '24 psi');
    expect(merged.values['RearTire']!['Pressure'], '27 psi');
    expect(
        controller
            .withSavedValues('other', 'setup', original)
            .values['FrontTire']!['Pressure'],
        '22 psi');
    repo.fail = true;
    final failed = await controller.updateField(
        'bike', 'setup', 'test', 'FrontTire', 'Pressure', '26 psi');
    expect(failed.isSuccess, isFalse);
    expect(
        controller
            .withSavedValues('bike', 'setup', original)
            .values['FrontTire']!['Pressure'],
        '24 psi');
    repo.fail = false;
    await controller.updateField(
        'bike', 'setup', 'test', 'FrontTire', 'Pressure', '26 psi');
    expect(
        controller
            .withSavedValues('bike', 'setup', merged)
            .values['FrontTire']!['Pressure'],
        '26 psi');
    controller.withSavedValues('bike', 'setup', repo.records['test']!);
    final external = original.copyWith(values: {
      'FrontTire': {'Pressure': '28 psi'}
    });
    expect(
        controller
            .withSavedValues('bike', 'setup', external)
            .values['FrontTire']!['Pressure'],
        '28 psi');
    controller.dispose();
    await repo.updates.close();
  });

  testWidgets('saved field updates the walkthrough before watch emits',
      (tester) async {
    final original = testExperiment(id: 'test', name: 'Test', before: {
      'FrontTire': {'Pressure': '22 psi'}
    }, values: {
      'FrontTire': {'Pressure': '23 psi'}
    });
    final repo = _DelayedWatchTests()..records['test'] = original;
    final deps = AppDependencies(
        testsRepository: (_) => repo,
        setupsRepository: (_) => FakeSetupsRepository());
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
                body: TestsView(
                    uid: 'user',
                    bike: 'bike',
                    setup: 'setup',
                    setupName: 'Default')))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue experiment'));
    await tester.tap(find.text('Continue experiment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Front pressure'));
    await tester.pumpAndSettle();
    tester
        .widget<SettingValueEditor>(find.byType(SettingValueEditor))
        .onChanged(24);
    await tester.tap(find.text('Save to experiment'));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(TestDraftFlow),
            matching: find.text('22 psi → 24 psi', findRichText: true)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(TestDraftFlow),
            matching: find.text('22 psi → 24 psi', findRichText: true)),
        findsOneWidget);
    expect(find.text('Start experiment'), findsOneWidget);
    repo.snapshots.add([original]);
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(TestDraftFlow),
            matching: find.text('22 psi → 24 psi', findRichText: true)),
        findsOneWidget);
    repo.snapshots.add(repo.records.values.toList());
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(TestDraftFlow),
            matching: find.text('22 psi → 24 psi', findRichText: true)),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    await repo.snapshots.close();
    await repo.updates.close();
  });

  test('draft progress survives serialization and failed writes', () async {
    final repo = MemoryTests()
      ..records['test'] =
          testExperiment(id: 'test', name: 'Test', before: {}, values: {});
    final controller = TestsController(repo, FakeSetupsRepository());
    expect(
        (await controller.moveDraftStep('bike', 'setup', 'test', 2)).isSuccess,
        isTrue);
    final restored = SetupTest.fromMap(repo.records['test']!.toMap());
    expect(restored.draftStep, 2);
    final missingSnapshot = restored.toMap()..remove('setupInformation');
    expect(() => SetupTest.fromMap(missingSnapshot), throwsA(isA<TypeError>()));
    repo.fail = true;
    expect(
        (await controller.moveDraftStep('bike', 'setup', 'test', 3)).isSuccess,
        isFalse);
    expect(repo.records['test']!.draftStep, 2);
    controller.dispose();
    await repo.updates.close();
  });

  testWidgets(
      'creation opens through a stale cache; unchanged and failed steps are safe',
      (tester) async {
    final repo = _CachedFirstTests();
    final setups = FakeSetupsRepository();
    setups.information['setup'] = {
      SetupConfiguration.metadataKey: SetupConfiguration({
        'FrontTire': ['Pressure'],
        'Fork': ['Rebound'],
      }).encode(),
    };
    setups.settings['bike/setup/FrontTire/Pressure'] = '22 psi';
    setups.settings['bike/setup/Fork/Rebound'] = '6 clicks';
    final deps = AppDependencies(
        testsRepository: (_) => repo, setupsRepository: (_) => setups);
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
                body: TestsView(
                    uid: 'user',
                    bike: 'bike',
                    setup: 'setup',
                    setupName: 'Default')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create experiment'));
    await tester.pumpAndSettle();
    expect(find.byType(TestDraftFlow), findsOneWidget);
    expect(repo.records, hasLength(1));
    expect(find.text('Tires'), findsOneWidget);
    expect(find.text('Leave as is'), findsOneWidget);
    expect(repo.records.values.single.changes, isEmpty);
    await tester.tap(find.text('Front pressure'));
    await tester.pumpAndSettle();
    tester
        .widget<SettingValueEditor>(find.byType(SettingValueEditor))
        .onChanged(24);
    repo.fail = true;
    await tester.tap(find.text('Save to experiment'));
    await tester.pumpAndSettle();
    expect(repo.records.values.single.changes, isEmpty);
    repo.fail = false;
    await tester.tap(find.text('Save to experiment'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Start experiment'), findsOneWidget);
    expect(find.text('Fork'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Tires'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    await repo.updates.close();
  });
}

// A fresh Firestore subscription can initially deliver an older cached list.
class _CachedFirstTests extends MemoryTests {
  bool created = false;

  @override
  Future<void> create(String bike, String setup, SetupTest test) async {
    await super.create(bike, setup, test);
    created = true;
  }

  @override
  Stream<List<SetupTest>> watch(String bike, String setup) async* {
    if (created) yield [];
    yield* super.watch(bike, setup);
  }
}

class _DelayedWatchTests extends MemoryTests {
  final snapshots = StreamController<List<SetupTest>>.broadcast();
  @override
  Stream<List<SetupTest>> watch(String bike, String setup) async* {
    yield records.values.toList();
    yield* snapshots.stream;
  }
}
