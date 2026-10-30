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
  for (final width in [390.0, 1440.0]) {
    testWidgets('test settings use a sheet and preserve edits at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryTests()
        ..records['test'] = SetupTest(id: 'test', name: 'Test', before: {
          'FrontTire': {'Pressure': '22 psi'}
        }, values: {
          'FrontTire': {'Pressure': '22 psi'}
        });
      final deps = AppDependencies(
          testsRepository: (_) => repo,
          setupsRepository: (_) => FakeSetupsRepository());
      await tester.pumpWidget(Provider.value(
          value: deps,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => PhoneViewport(child: child!),
              home: const Scaffold(
                  body: TestsView(
                      uid: 'user',
                      bike: 'bike',
                      setup: 'setup',
                      setupName: 'Default')))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Front pressure'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.getSize(find.byType(BottomSheet)).width,
          width.clamp(0, kPhoneMaxWidth));
      tester
          .widget<SettingValueEditor>(find.byType(SettingValueEditor))
          .onChanged(24);
      await tester.tap(find.text('Save to test'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(repo.records['test']!.values['FrontTire']!['Pressure'], '24 psi');
      expect(repo.records['test']!.before['FrontTire']!['Pressure'], '22 psi');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      deps.dispose();
      await repo.updates.close();
    });
  }
}
