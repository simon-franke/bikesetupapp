import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/widgets/adaptive_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1024.0]) {
    testWidgets('modal adapts to window width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var saved = false;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.dark]),
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => showAdaptiveModal<void>(
                      context: context,
                      builder: (context) =>
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            const AppSheetHandle(),
                            const TextField(),
                            FilledButton(
                                onPressed: () {
                                  saved = true;
                                  Navigator.pop(context);
                                },
                                child: const Text('Save')),
                          ])),
                  child: const Text('Open'),
                ))),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), width >= 768 ? findsOneWidget : findsNothing);
      expect(find.byType(BottomSheet),
          width < 768 ? findsOneWidget : findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('tablet form scrolls with keyboard and enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      theme: ThemeData(extensions: const [AppPalette.dark]),
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => showAdaptiveModal<void>(
                    context: context,
                    builder: (context) =>
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          for (var i = 0; i < 20; i++)
                            SizedBox(height: 60, child: Text('Field $i')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Save')),
                        ])),
                child: const Text('Open'),
              ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
