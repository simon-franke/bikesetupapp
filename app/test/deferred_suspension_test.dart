import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/controllers/setups_controller.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/features/setups/ui/add_category_sheet.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_repositories.dart';

void main() {
  for (final category in ['Fork', 'Shock']) {
    for (final type in ['Air', 'Coil']) {
      test('adding $type $category saves its type and starting fields together',
          () async {
        final repository = FakeSetupsRepository();
        repository.information['s'] = {
          SetupConfiguration.metadataKey: SetupConfiguration({
            'FrontTire': ['Pressure'],
            'RearTire': ['Pressure'],
          }).encode(),
          'custom': 'keep',
        };
        repository.names['s'] = 'Baseline';
        // Removing and re-adding a category must preserve existing measurements.
        repository.settings['b/s/$category/Rebound'] = '4 clicks';
        final controller = SetupsController(repository);
        final result = await controller.setCategoryEnabled(
            'b', 's', category, true,
            suspensionType: type,
            addedFields: {
              category: suspensionFields(type, ['Rebound', 'Compression'])
            });
        expect(result.isSuccess, true);
        final info = repository.information['s']!;
        expect(info[category.toLowerCase()], type);
        expect(info['custom'], 'keep');
        final fields = SetupConfiguration.fromInformation(info).fields;
        expect(fields['FrontTire'], ['Pressure']);
        expect(
            fields[category],
            containsAll(type == 'Air'
                ? ['Pressure', 'Tokens']
                : ['Spring Rate', 'Preload']));
        expect(fields[category],
            isNot(contains(type == 'Air' ? 'Spring Rate' : 'Pressure')));
        expect(repository.settings['b/s/$category/Rebound'], '4 clicks');
        controller.dispose();
      });
    }
  }
  testWidgets('suspension prompt supports dismissal and an explicit choice',
      (tester) async {
    String? selected;
    var completed = false;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                      child: const Text('Add fork'),
                      onPressed: () async {
                        selected =
                            await showSuspensionTypeSheet(context, 'Fork');
                        completed = true;
                      },
                    )))));
    await tester.tap(find.text('Add fork'));
    await tester.pumpAndSettle();
    expect(find.text('What kind of fork?'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(completed, true);
    expect(selected, isNull);
    await tester.tap(find.text('Add fork'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coil'));
    await tester.pumpAndSettle();
    expect(selected, 'Coil');
    expect(tester.takeException(), isNull);
  });
}
