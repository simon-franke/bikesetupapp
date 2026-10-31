import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/workspace/ui/workspace_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final reduced in [false, true]) {
    testWidgets('bike label stays fixed across tabs, reduced motion $reduced',
        (tester) async {
      Widget host(bool service, {String? summary}) => MaterialApp(
            theme: ThemeData(extensions: const [AppPalette.dark]),
            home: MediaQuery(
              data: MediaQueryData(
                  disableAnimations: reduced,
                  textScaler: TextScaler.linear(1.5)),
              child: Center(
                  child: SizedBox(
                      width: 240,
                      child: WorkspaceTitle(
                          bikeName: 'Trail bike',
                          setupName: 'Weekend',
                          bikeOnly: service,
                          activitySummary: summary))),
            ),
          );
      await tester.pumpWidget(host(false));
      final bounds = tester.getRect(find.byType(WorkspaceTitle));
      final bikePosition = tester.getTopLeft(find.text('Trail bike'));
      await tester.pumpWidget(host(true, summary: '120 km   4 h'));
      await tester.pump(const Duration(milliseconds: 90));
      expect(tester.getTopLeft(find.text('Trail bike')), bikePosition);
      expect(tester.widget<Text>(find.text('Trail bike')).style!.fontSize, 12);
      await tester.pumpAndSettle();
      expect(find.text('120 km   4 h'), findsOneWidget);
      expect(find.text('Weekend'), findsNothing);
      expect(tester.getRect(find.byType(WorkspaceTitle)), bounds);
      await tester.pumpWidget(host(true));
      await tester.pumpAndSettle();
      expect(find.text('No rides yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final reduced in [false, true]) {
    testWidgets('odometer rolls and settles, reduced motion $reduced',
        (tester) async {
      Widget host(double? mileage) => MaterialApp(
            theme: ThemeData(extensions: const [AppPalette.dark]),
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Center(
                  child: SizedBox(
                      width: 260,
                      child: WorkspaceTitle(
                        bikeName: 'Trail bike',
                        setupName: 'Default',
                        bikeOnly: true,
                        mileageKm: mileage,
                        hours: 6,
                      ))),
            ),
          );
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(105));
      final bounds = tester.getRect(find.byType(WorkspaceTitle));
      expect(find.bySemanticsLabel('105 km   6.0 h'), findsOneWidget);
      final animation = find.byWidgetPredicate(
          (widget) => widget is TweenAnimationBuilder<double>);
      final initial = tester.widget<TweenAnimationBuilder<double>>(animation);
      expect(initial.duration,
          reduced ? Duration.zero : const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 275));
      expect(tester.getRect(find.byType(WorkspaceTitle)), bounds);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.getRect(find.byType(WorkspaceTitle)), bounds);
      final settled = tester.state(animation);
      await tester.pumpWidget(host(105));
      expect(tester.state(animation), same(settled));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(null));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('6.0 h'), findsOneWidget);
      expect(animation, findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
