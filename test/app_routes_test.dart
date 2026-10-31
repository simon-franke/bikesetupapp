import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final nested in [false, true]) {
    for (final reduced in [false, true]) {
      testWidgets(
          'iOS back swipe completes and cancels, nested=$nested, '
          'reduced=$reduced', (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        const root = Scaffold(body: Text('Setup root'));
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          navigatorKey: nested ? null : navigator,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: nested
              ? Scaffold(
                  body: NavigatorPopHandler(
                    onPopWithResult: (_) => navigator.currentState!.pop(),
                    child: Navigator(
                      key: navigator,
                      onGenerateRoute: (_) =>
                          MaterialPageRoute<void>(builder: (_) => root),
                    ),
                  ),
                )
              : root,
        ));
        navigator.currentState!.push(AppRoutes.fadeSlide<void>(
            const Scaffold(body: Text('Tires detail'))));
        await tester.pumpAndSettle();

        // A short, slow drag should settle back on the detail page.
        var gesture = await tester.startGesture(const Offset(1, 200));
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump(const Duration(milliseconds: 300));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('Tires detail'), findsOneWidget);
        expect(navigator.currentState!.canPop(), isTrue);

        gesture = await tester.startGesture(const Offset(1, 200));
        await gesture.moveBy(const Offset(600, 0));
        await tester.pump(const Duration(milliseconds: 300));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('Tires detail'), findsNothing);
        expect(find.text('Setup root'), findsOneWidget);
        expect(navigator.currentState!.canPop(), isFalse);
      });
    }
  }

  testWidgets('iOS back swipe respects a guarded form', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      navigatorKey: navigator,
      home: const Scaffold(),
    ));
    navigator.currentState!.push(AppRoutes.fadeSlide<void>(const PopScope(
      canPop: false,
      child: Scaffold(body: Text('Saving form')),
    )));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(1, 200), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Saving form'), findsOneWidget);
    expect(navigator.currentState!.canPop(), isTrue);
  });
}
