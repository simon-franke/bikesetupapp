import 'dart:math' as math;
import 'package:bikesetupapp/main.dart';
import 'package:bikesetupapp/features/settings/controllers/app_state_notifier.dart';
import 'package:provider/provider.dart';
import 'package:bikesetupapp/common/layout/phone_viewport.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/features/auth/ui/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app root constrains the navigator on wide screens',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AppStateNotifier(ThemeMode.light),
        child: const MyApp(
            isSignedIn: false,
            user: null,
            defaultBikeID: '',
            defaultBike: '',
            defaultSetupID: '',
            defaultSetup: '')));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(Scaffold)),
        const Rect.fromLTWH(480, 0, 480, 900));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 700),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
    const Size(1024, 320)
  ]) {
    testWidgets('phone viewport bounds routes and sheets at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Size? logicalSize;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => PhoneViewport(child: child!),
        home: Builder(builder: (context) {
          logicalSize = MediaQuery.sizeOf(context);
          return Scaffold(
              key: const Key('home'),
              body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (context) => Scaffold(
                              key: const Key('route'),
                              body: TextButton(
                                  onPressed: () => showAppSheet<void>(
                                      context: context,
                                      builder: (_) => const SizedBox(
                                          height: 100,
                                          child: Text('Sheet content'))),
                                  child: const Text('Open sheet'))))),
                  child: const Text('Next route')));
        }),
      ));
      final width = math.min(size.width, kPhoneMaxWidth);
      expect(logicalSize, Size(width, size.height));
      final home = tester.getRect(find.byKey(const Key('home')));
      expect(home.width, width);
      expect(home.left, (size.width - width) / 2);
      await tester.tap(find.text('Next route'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('route'))).width, width);
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      final sheet = tester.getRect(find.byType(BottomSheet));
      expect(sheet.width, width);
      expect(sheet.left, home.left);
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone sign-in fits $size with enlarged text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: PhoneViewport(child: child!)),
          home: const LoginPage()));
      await tester.pumpAndSettle();
      expect(find.text('Clickwise'), findsOneWidget);
      expect(tester.getSize(find.byType(Scaffold)).width,
          math.min(size.width, kPhoneMaxWidth));
      expect(tester.takeException(), isNull);
    });
  }
}
