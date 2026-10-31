import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/features/setups/ui/add_category_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets(
      'add category shares suggestion rows and creates a named category',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    String? selected;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () async => selected =
                        await showAddCategorySheet(context,
                            {'FrontTire', 'RearTire', 'GeneralSettings'}),
                    child: const Text('Open'),
                  ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(AppSuggestionTile), findsNWidgets(6));
    expect(find.text('Tires'), findsNothing);
    await tester.tap(find.text('Add new'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bike fit');
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(find.text('This category already exists.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Drivetrain');
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(selected, 'Drivetrain');
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
