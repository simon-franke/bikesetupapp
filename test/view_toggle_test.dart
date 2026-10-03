import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/widgets/view_toggle.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show SemanticsAction, Tristate;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'labeled tabs change view and announce selection and service alerts',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var activeView = ActiveView.setup;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ViewToggle(
              activeView: activeView,
              showServiceAlert: true,
              onChanged: (view) => setState(() => activeView = view),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Setup'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    expect(
        tester
            .getSemantics(find.bySemanticsLabel('Setup'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue);

    expect(
        tester
            .getSemantics(find.bySemanticsLabel('Service, maintenance due'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue);

    await tester.tap(find.text('Service'));
    await tester.pump();
    expect(activeView, ActiveView.services);
    expect(
        tester
            .getSemantics(find.bySemanticsLabel('Service, maintenance due'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue);
    expect(
        tester
            .getSemantics(find.bySemanticsLabel('Setup'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isFalse);

    await tester.tap(find.text('Setup'));
    await tester.pump();
    expect(activeView, ActiveView.setup);
    semantics.dispose();
  });

  testWidgets('tabs fit a narrow phone with enlarged text and usable targets',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.dark]),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 280,
                child: ViewToggle(
                  activeView: ActiveView.setup,
                  showServiceAlert: true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final target in tester.widgetList<InkWell>(find.byType(InkWell))) {
      expect(tester.getSize(find.byWidget(target)).height,
          greaterThanOrEqualTo(44));
    }
  });
}
