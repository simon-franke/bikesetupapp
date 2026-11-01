import 'package:bikesetupapp/common/layout/phone_viewport.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('discard waits until the menu has finished closing',
      (tester) async {
    var discarded = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
          body: AppObjectMenu(
        tooltip: 'Experiment options',
        onRename: null,
        onDiscard: () => discarded = true,
      )),
    ));
    await tester.tap(find.byTooltip('Experiment options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard draft'));
    await tester.pump();
    expect(discarded, isFalse);
    await tester.pump(const Duration(milliseconds: 75));
    expect(discarded, isFalse);
    await tester.pumpAndSettle();
    expect(discarded, isTrue);
    expect(find.text('Discard draft'), findsNothing);
  });

  for (final width in [320.0, 1440.0]) {
    testWidgets('object menu stays in phone viewport and dismisses at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var renamed = 0;
      var discarded = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) => PhoneViewport(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: AppObjectMenu(
                tooltip: 'Experiment options',
                onRename: () => renamed++,
                onDiscard: () => discarded++),
          ),
        ),
      ));
      await tester.tap(find.byTooltip('Experiment options'));
      await tester.pumpAndSettle();
      final action = find.widgetWithText(TextButton, 'Rename');
      final bounds = tester.getRect(action);
      final viewport = tester.getRect(find.byType(Scaffold));
      expect(bounds.left, greaterThanOrEqualTo(viewport.left));
      expect(bounds.right, lessThanOrEqualTo(viewport.right));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom));
      await tester.tapAt(viewport.topLeft + const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
      expect(renamed, 0);

      await tester.tap(find.byTooltip('Experiment options'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
      expect(renamed, 0);

      await tester.tap(find.byTooltip('Experiment options'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(renamed, 1);
      expect(find.text('Rename'), findsNothing);
      await tester.tap(find.byTooltip('Experiment options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard draft'));
      await tester.pumpAndSettle();
      expect(discarded, 1);
      expect(renamed, 1);
      expect(find.text('Discard draft'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
