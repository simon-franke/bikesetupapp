import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/ui/draft_value_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unit menu converts back without rounding and uses typed value',
      (tester) async {
    String saved = '';
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
            body: DraftValueEditor(
                field: 'Pressure',
                value: '31 psi',
                onChanged: (value) => saved = value))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('psi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bar'));
    await tester.pumpAndSettle();
    expect(find.text('2.1'), findsOneWidget);
    await tester.tap(find.text('bar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('psi'));
    await tester.pumpAndSettle();
    expect(saved, '31 psi');
    await tester.tap(find.text('31'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '45');
    await tester.tap(find.text('psi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bar'));
    await tester.pumpAndSettle();
    expect(find.text('3.1'), findsOneWidget);
    expect(saved, '3.1 bar');
    expect(tester.takeException(), isNull);
  });
}
