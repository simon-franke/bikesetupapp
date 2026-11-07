import 'package:bikesetupapp/app/routing/app_motion.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('outgoing screen keeps its state throughout the transition',
      (tester) async {
    Widget screen(bool editing) => MaterialApp(
          home: AppScreenTransition(
            child: editing
                ? const Scaffold(key: ValueKey('form'), body: TextField())
                : const Scaffold(key: ValueKey('next'), body: Text('Next')),
          ),
        );
    await tester.pumpWidget(screen(true));
    await tester.enterText(find.byType(TextField), 'My bike');
    await tester.pumpWidget(screen(false));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('My bike'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('My bike'), findsNothing);
  });

  testWidgets('replacement fades and outgoing content cannot be tapped',
      (tester) async {
    var taps = 0;
    Widget screen(int id) => MaterialApp(
            home: AppScreenTransition(
          child: Scaffold(
              key: ValueKey(id),
              body: Center(
                  child: TextButton(
                      onPressed: () => taps++, child: Text('Screen $id')))),
        ));
    await tester.pumpWidget(screen(1));
    await tester.pumpWidget(screen(2));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Screen 1'), findsOneWidget);
    expect(find.text('Screen 2'), findsOneWidget);
    expect(
        find.ancestor(
            of: find.text('Screen 1'), matching: find.byType(IgnorePointer)),
        findsWidgets);
    await tester.tap(find.text('Screen 2'));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(find.text('Screen 1'), findsNothing);
  });

  testWidgets('reduced motion replaces screens immediately', (tester) async {
    Widget screen(int id) => MaterialApp(
            home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child:
              AppScreenTransition(child: Text('Screen $id', key: ValueKey(id))),
        ));
    await tester.pumpWidget(screen(1));
    await tester.pumpWidget(screen(2));
    expect(find.text('Screen 1'), findsNothing);
    expect(find.text('Screen 2'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNothing);
  });

  testWidgets('sheet result waits for the closing animation', (tester) async {
    var finished = false;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                      child: const Text('Open'),
                      onPressed: () async {
                        await showAppSheet<void>(
                            context: context,
                            builder: (sheet) => TextButton(
                                onPressed: () => Navigator.pop(sheet),
                                child: const Text('Close')));
                        finished = true;
                      },
                    )))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pump();
    expect(finished, false);
    await tester.pumpAndSettle();
    expect(finished, true);
  });
}
