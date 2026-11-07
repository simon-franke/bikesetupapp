import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/workspace/ui/view_toggle.dart';
import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('prebuilt tabs select at narrow width, reduce motion $reduced',
        (tester) async {
      var selected = ActiveView.setup;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(extensions: const [AppPalette.dark]),
          home: MediaQuery(
              data: MediaQueryData(
                  size: const Size(320, 700),
                  viewPadding: const EdgeInsets.only(bottom: 34),
                  disableAnimations: reduced,
                  textScaler: TextScaler.linear(2)),
              child: StatefulBuilder(
                  builder: (context, setState) => Scaffold(
                      bottomNavigationBar: ViewToggle(
                          activeView: selected,
                          onChanged: (value) =>
                              setState(() => selected = value)))))));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoLiquidGlass), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      final inset = tester
          .widget<Padding>(find.byKey(const ValueKey('navigation-inset')));
      expect((inset.padding as EdgeInsets).bottom, 22);
      await tester.tap(find.text('Experiments'));
      await tester.pumpAndSettle();
      expect(selected, ActiveView.tests);
      await tester.tap(find.text('Service'));
      await tester.pumpAndSettle();
      expect(selected, ActiveView.services);
      expect(tester.takeException(), isNull);
    });
  }
}
