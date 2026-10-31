import 'package:bikesetupapp/features/tests/ui/test_draft_flow.dart';
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

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('test settings use a sheet and preserve edits at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryTests()
        ..records['test'] = SetupTest(id: 'test', name: 'Test', before: {
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
          find.text('Continue test').hitTestable(), 300);
      await tester.tap(find.text('Continue test'));
      await tester.pumpAndSettle();
      expect(find.text('Tires'), findsOneWidget);
      await tester.tap(find.text('Front pressure'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNWidgets(2));
      expect(find.byType(Dialog), findsNothing);
      expect(tester.getSize(find.byType(BottomSheet).last).width,
          width.clamp(0, kPhoneMaxWidth));
      tester
          .widget<SettingValueEditor>(find.byType(SettingValueEditor))
          .onChanged(24);
      await tester.tap(find.text('Save to test'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(repo.records['test']!.values['FrontTire']!['Pressure'], '24 psi');
      expect(repo.records['test']!.before['FrontTire']!['Pressure'], '22 psi');
      expect(find.text('from 22 psi'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Compression'), findsOneWidget);
      expect(repo.records['test']!.draftStep, 1);
      await tester.tap(find.byTooltip('Close test'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.text('Continue test').hitTestable(), 300);
      await tester.tap(find.text('Continue test'));
      await tester.pumpAndSettle();
      expect(find.text('Fork'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('from 22 psi'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave as is'));
      await tester.pumpAndSettle();
      expect(find.text('Ready to try it?'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(TestDraftFlow),
              matching: find.text('22 psi → 24 psi', findRichText: true)),
          findsOneWidget);
      expect(find.text('Tires'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      await tester.tap(find.text('Front pressure'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Ready to try it?'), findsOneWidget);
      expect(repo.records['test']!.draftStep, 2);
      await tester.tap(find.byTooltip('Close test'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
      expect(find.text('Discard draft'), findsNothing);
      await tester.ensureVisible(find.byTooltip('Test options'));
      await tester.tap(find.byTooltip('Test options'));
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
          find.text('Continue test').hitTestable(), 300);
      await tester.tap(find.text('Continue test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start test'));
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
