import 'dart:io';
import 'dart:ui' as ui;
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Sora')
          ..addFont(rootBundle.load('assets/fonts/Sora.ttf')))
        .load();
  });

  testWidgets('busy action keeps its size and blocks repeat submissions',
      (tester) async {
    var calls = 0;
    Widget screen(bool busy) => MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 340,
                    child: AppTactileButton(
                        isLoading: busy,
                        loadingLabel: 'Adding bike…',
                        onPressed: () => calls++,
                        child: const Text('Add bike'))))));
    await tester.pumpWidget(screen(false));
    final before = tester.getSize(find.byType(AppTactileButton));
    await tester.pumpWidget(screen(true));
    expect(tester.getSize(find.byType(AppTactileButton)), before);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 0);
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
    expect(find.text('Adding bike…'), findsOneWidget);
    await tester.pumpWidget(screen(false));
    await tester.pumpAndSettle();
    expect(find.byType(AppLoadingIndicator), findsNothing);
  });

  testWidgets('reduced motion and hidden loaders do not schedule animation',
      (tester) async {
    for (final reduced in [true, false]) {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: TickerMode(
                  enabled: reduced, child: const AppLoadingState()))));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, false);
      expect(find.text('Loading…'), findsOneWidget);
    }
  });

  testWidgets('loading treatments fit large text and render their click cycle',
      (tester) async {
    tester.view.physicalSize = const Size(390, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    Widget screen(double scale) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
                key: boundary,
                child: Scaffold(
                    body: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(
                                  child: Center(
                                      child: AppLoadingState(
                                          label: 'Loading your bikes…'))),
                              AppTactileButton(
                                  isLoading: true,
                                  loadingLabel: 'Adding bike…',
                                  onPressed: () {},
                                  child: const Text('Add bike')),
                            ]))))));
    await tester.pumpWidget(screen(2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(screen(1));
    final output = Platform.environment['LOADING_REVIEW_OUTPUT'];

    for (var frame = 0; frame < (output == null ? 36 : 144); frame++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (output != null) {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/frame-${frame.toString().padLeft(2, '0')}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
