import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final palette in [AppPalette.dark, AppPalette.light]) {
    testWidgets(
        'shared controls preserve input, errors and disabled actions ($palette)',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var saves = 0;
      var changes = '';
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: [palette]),
        home: Scaffold(
            body: Column(children: [
          AppTextField(
              controller: controller,
              hint: 'Bike name',
              errorText: 'Name required',
              onChanged: (value) => changes = value),
          AppActionButton(label: 'Save', onPressed: () => saves++),
          const AppActionButton(label: 'Unavailable', onPressed: null),
        ])),
      ));
      await tester.enterText(find.byType(TextField), 'Trail bike');
      expect(controller.text, 'Trail bike');
      expect(changes, 'Trail bike');
      expect(find.text('Name required'), findsOneWidget);
      await tester.tap(find.text('Save'));
      expect(saves, 1);
      final disabled = tester.widget<FilledButton>(find.ancestor(
          of: find.text('Unavailable'), matching: find.byType(FilledButton)));
      expect(disabled.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
