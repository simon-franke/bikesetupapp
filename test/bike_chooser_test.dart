import 'dart:ui' show Tristate;

import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_chooser_sheet.dart';
import 'package:bikesetupapp/features/bikes/ui/setup_choice_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child, {double scale = 1}) => MaterialApp(
      theme: ThemeData(extensions: const [AppPalette.dark]),
      home: Scaffold(
          body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, height: 500, child: child)),
      )),
    );

void main() {
  testWidgets('setup details and editing do not trigger selection',
      (tester) async {
    var selected = 0;
    var edited = 0;
    var details = 0;
    await tester.pumpWidget(harness(SetupChoiceTile(
      name: 'Default',
      isSelected: true,
      onSelect: () => selected++,
      onEdit: () => edited++,
      onDetails: () => details++,
    )));
    await tester.tap(find.byTooltip('Setup details'));
    await tester.tap(find.byTooltip('Edit setup'));
    expect(details, 1);
    expect(edited, 1);
    expect(selected, 0);
    await tester.tap(find.text('Default'));
    expect(selected, 1);
    expect(find.text('Current setup'), findsOneWidget);
  });

  testWidgets('only the selected setup announces selection and shows details',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(Column(children: [
      SetupChoiceTile(
          name: 'Default',
          isSelected: false,
          onSelect: () {},
          onEdit: () {},
          onDetails: () {}),
      SetupChoiceTile(
          name: 'Race day',
          isSelected: true,
          onSelect: () {},
          onEdit: () {},
          onDetails: () {}),
    ])));
    expect(find.text('Current setup'), findsOneWidget);
    expect(find.byTooltip('Setup details'), findsOneWidget);
    expect(
        tester
            .getSemantics(find.text('Race day'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets(
      'chooser keeps Add bike visible while a long list scrolls at enlarged text',
      (tester) async {
    var added = 0;
    await tester.pumpWidget(harness(
        BikeChooserContent(
          onAddBike: () => added++,
          bikeList: ListView(
              children: List.generate(
                  20,
                  (index) => SetupChoiceTile(
                        name: 'Bike $index trail setup',
                        isSelected: index == 0,
                        onSelect: () {},
                        onEdit: () {},
                        onDetails: () {},
                      ))),
        ),
        scale: 2));
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add bike'));
    expect(added, 1);
    expect(tester.takeException(), isNull);
  });
  for (final count in [2, 20]) {
    testWidgets('tablet chooser fits $count bikes and keeps actions visible',
        (tester) async {
      var added = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
          child: BikeChooserContent(
            compact: true,
            onAddBike: () => added++,
            bikeList: ListView(
                shrinkWrap: true,
                children: List.generate(count,
                    (i) => SizedBox(height: 72, child: Text('Bike $i')))),
          ),
        ))),
      ));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(BikeChooserContent)).height,
          count == 2 ? lessThan(400) : lessThanOrEqualTo(480));
      expect(find.byTooltip('Close bike chooser'), findsOneWidget);
      if (count == 20) {
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Add bike'));
      expect(added, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
