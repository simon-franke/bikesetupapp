import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/ui/add_field_bottom_sheet.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'support/fake_repositories.dart';

class SheetUser extends Fake implements User {
  @override
  String get uid => 'user';
}

void main() {
  testWidgets('suggestions hide existing settings and save only from editor',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final repo = FakeSetupsRepository()
      ..settings['bike/setup/Fork/High Speed Rebound'] = '2 clicks'
      ..settings['bike/setup/Fork/Sag'] = '  ';
    await tester.pumpWidget(Provider.value(
      value: AppDependencies(setupsRepository: (_) => repo),
      child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showAddFieldSheet(context,
                          user: SheetUser(),
                          uBikeID: 'bike',
                          category: 'Fork',
                          uSetupID: 'setup'),
                      child: const Text('Open'))))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('High Speed Rebound'), findsNothing);
    expect(find.text('Suggested fields'), findsNothing);
    await tester.tap(find.text('Sag'));
    await tester.pumpAndSettle();
    expect(repo.settings['bike/setup/Fork/Sag'], '  ');
    expect(find.text('Save to experiment'), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add setting'));
    await tester.pumpAndSettle();
    expect(repo.settings['bike/setup/Fork/Sag']!.trim(), isNotEmpty);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final category in ['Fork', 'No suggestions']) {
    testWidgets('opens new setting directly for $category with no suggestions',
        (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final repo = FakeSetupsRepository();
      for (final key in kSuggestedFieldKeys[category] ?? <String>[]) {
        repo.settings['bike/setup/$category/$key'] = '1';
      }
      await tester.pumpWidget(Provider.value(
        value: AppDependencies(setupsRepository: (_) => repo),
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => showAddFieldSheet(context,
                            user: SheetUser(),
                            uBikeID: 'bike',
                            category: category,
                            uSetupID: 'setup'),
                        child: const Text('Open'))))),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('New setting'), findsOneWidget);
      expect(find.text('Setting name'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('New setting…'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
