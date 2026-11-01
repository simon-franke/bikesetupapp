import 'package:bikesetupapp/features/tests/ui/test_draft_flow.dart';
import 'package:bikesetupapp/features/setups/ui/setup_category_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/layout/phone_viewport.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:bikesetupapp/features/tests/models/setup_test.dart';
import 'package:bikesetupapp/features/tests/ui/tests_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_repositories.dart';
import 'support/fake_tests_repository.dart';

class MetadataUser extends Fake implements User {
  @override
  String get uid => 'user';
}

void main() {
  testWidgets('category hides missing and blank values but keeps zero',
      (tester) async {
    final setups = FakeSetupsRepository()
      ..settings['bike/setup/Fork/Pressure'] = '93'
      ..settings['bike/setup/Fork/Tokens'] = '0'
      ..settings['bike/setup/Fork/Low Speed Rebound'] = '  '
      ..settings['bike/setup/Fork/High Speed Rebound'] = '';
    final deps = AppDependencies(setupsRepository: (_) => setups);
    await tester.pumpWidget(Provider.value(
      value: deps,
      child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
              body: SetupCategoryView(
                  configuration: testSetupConfiguration,
                  user: MetadataUser(),
                  bike: 'bike',
                  setup: 'setup',
                  category: 'Fork'))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Pressure'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Low Speed Rebound'), findsNothing);
    expect(find.text('High Speed Rebound'), findsNothing);
    expect(find.text('Low Speed Compression'), findsNothing);
    expect(find.text('Add'), findsNothing);
    expect(find.byTooltip('Add fork setting'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
  });

  for (final experiment in [false, true]) {
    testWidgets('numeric free text retains its type in experiment=$experiment',
        (tester) async {
      final setups = FakeSetupsRepository()
        ..settings['bike/setup/Custom/Serial'] = '123'
        ..metadata['bike/setup/Custom/Serial'] = 'freeText';
      final draft = testExperiment(id: 'test', name: 'Test', before: {
        'Custom': {'Serial': '123'}
      }, values: {
        'Custom': {'Serial': '123'}
      }, fieldMetadata: {
        'Custom': {'Serial': 'freeText'}
      });
      final tests = MemoryTests()..records['test'] = draft;
      final deps = AppDependencies(
          testsRepository: (_) => tests, setupsRepository: (_) => setups);
      await tester.pumpWidget(Provider.value(
          value: deps,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                  body: experiment
                      ? TestDraftFlow(
                          uid: 'user',
                          bike: 'bike',
                          setup: 'setup',
                          initial: draft,
                          nameFor: (test) => test.name)
                      : SetupCategoryView(
                          configuration: testSetupConfiguration,
                          user: MetadataUser(),
                          bike: 'bike',
                          setup: 'setup',
                          category: 'Custom')))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Serial'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingValueEditor), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '123');
      await tester.enterText(find.byType(TextField), 'ABC-123');
      await tester.tap(find.text(experiment ? 'Save to experiment' : 'Save'));
      await tester.pumpAndSettle();
      expect(
          experiment
              ? tests.records['test']!.values['Custom']!['Serial']
              : setups.settings['bike/setup/Custom/Serial'],
          'ABC-123');
      await tester.pumpWidget(const SizedBox());
      deps.dispose();
      await tests.updates.close();
    });
  }

  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('test settings use a sheet and preserve edits at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryTests()
        ..records['test'] = testExperiment(id: 'test', name: 'Test', before: {
          'FrontTire': {'Pressure': '22 psi'},
          'RearTire': {'Pressure': '25 psi'},
          'Fork': {'Compression': '4 clicks'}
        }, values: {
          'FrontTire': {'Pressure': '23 psi'},
          'RearTire': {'Pressure': '25 psi'},
          'Fork': {'Compression': '4 clicks'}
        });
      final deps = AppDependencies(
          testsRepository: (_) => repo,
          setupsRepository: (_) => FakeSetupsRepository());
      await tester.pumpWidget(Provider.value(
          value: deps,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => PhoneViewport(
                  child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(width == 320 ? 2 : 1)),
                      child: child!)),
              home: const Scaffold(
                  body: TestsView(
                      uid: 'user',
                      bike: 'bike',
                      setup: 'setup',
                      setupName: 'Default')))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.text('Continue experiment').hitTestable(), 300);
      await tester.tap(find.text('Continue experiment'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Front pressure'));
      await tester.tap(find.text('Front pressure'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNWidgets(2));
      expect(find.byType(Dialog), findsNothing);
      expect(tester.getSize(find.byType(BottomSheet).last).width,
          width.clamp(0, kPhoneMaxWidth));
      tester
          .widget<SettingValueEditor>(find.byType(SettingValueEditor))
          .onChanged(24);
      await tester.ensureVisible(find.text('Save to experiment'));
      await tester.tap(find.text('Save to experiment'));
      await tester.pumpAndSettle();
      expect(repo.records['test']!.values['FrontTire']!['Pressure'], '24 psi');
      expect(repo.records['test']!.before['FrontTire']!['Pressure'], '22 psi');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Fork'), findsOneWidget);
      expect(find.text('Compression'), findsOneWidget);
      expect(find.text('Start experiment'), findsOneWidget);
      await tester.tap(find.byTooltip('Close experiment'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
      expect(find.text('Discard draft'), findsNothing);
      await tester.ensureVisible(find.byTooltip('Experiment options'));
      await tester.tap(find.byTooltip('Experiment options'));
      await tester.pumpAndSettle();
      expect(find.text('Discard draft'), findsOneWidget);
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'More grip');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.records['test']!.name, 'More grip');
      await tester.scrollUntilVisible(
          find.text('Continue experiment').hitTestable(), 300);
      await tester.tap(find.text('Continue experiment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start experiment'));
      await tester.pumpAndSettle();
      expect(repo.records['test']!.stage, TestStage.ride);
      expect(repo.records['test']!.name, 'More grip');
      expect(repo.records['test']!.before['FrontTire']!['Pressure'], '22 psi');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      deps.dispose();
      await repo.updates.close();
    });
  }
}
