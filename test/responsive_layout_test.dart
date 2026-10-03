import 'package:bikesetupapp/features/setups/ui/control_panel_grid.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/features/auth/ui/google_sign_in.dart';
import 'package:bikesetupapp/common/layout/responsive_layout.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> render(WidgetTester tester, Size size, Widget child,
    {double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppPalette.dark]),
      home: MediaQuery(
          data:
              MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: child))));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(1366, 1024), const Size(1024, 1366)]) {
    testWidgets('tablet $size has adjacent diagram and settings panes',
        (tester) async {
      await render(
          tester,
          size,
          AppContentFrame(
              child: SetupWorkspace(
            diagramBuilder: (width, height) =>
                SizedBox(key: const Key('diagram'), height: height),
            settings: const SizedBox(key: Key('settings'), height: 420),
          )));
      final diagram = tester.getRect(find.byKey(const Key('diagram')));
      final settings = tester.getRect(find.byKey(const Key('settings')));
      expect(settings.left, diagram.right + 25);
      expect(diagram.width, size.width / 2);
      expect(settings.top, diagram.top);
      expect(diagram.height, size.height);
      expect(settings.width + 25, diagram.width);
      expect(settings.height, 420);
      expect(settings.bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Split View and enlarged text stack the setup panes',
      (tester) async {
    for (final scenario in [
      (const Size(600, 900), 1.0),
      (const Size(1024, 1366), 2.0)
    ]) {
      await render(
          tester,
          scenario.$1,
          SetupWorkspace(
            diagramBuilder: (width, height) =>
                SizedBox(key: const Key('diagram'), height: height),
            settings: const SizedBox(key: Key('settings'), height: 420),
          ),
          scale: scenario.$2);
      expect(
          tester.getRect(find.byKey(const Key('settings'))).top,
          greaterThanOrEqualTo(
              tester.getRect(find.byKey(const Key('diagram'))).bottom));
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('diagram fits a shallow side-by-side workspace', (tester) async {
    await render(
        tester,
        const Size(1024, 400),
        SetupWorkspace(
          diagramBuilder: (width, height) =>
              SizedBox(key: const Key('diagram'), height: height),
          settings: const SizedBox(height: 350),
        ));
    expect(tester.getSize(find.byKey(const Key('diagram'))).height,
        lessThanOrEqualTo(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('short tablet windows scroll the whole stacked workspace',
      (tester) async {
    await render(
        tester,
        const Size(1024, 320),
        SetupWorkspace(
          diagramBuilder: (width, height) =>
              SizedBox(key: const Key('diagram'), height: height),
          settings: const SizedBox(
              height: 600,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text('Last setting'))),
        ));
    expect(tester.getTopLeft(find.text('Last setting')).dy, greaterThan(320));
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.text('Last setting')).dy,
        lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('service cards use two columns and adapt to enlarged text',
      (tester) async {
    final children =
        List.generate(3, (i) => SizedBox(key: Key('card$i'), height: 150));
    await render(
        tester, const Size(1024, 1366), ResponsiveCardGrid(children: children));
    expect(tester.getTopLeft(find.byKey(const Key('card0'))).dy,
        tester.getTopLeft(find.byKey(const Key('card1'))).dy);
    expect(tester.getTopLeft(find.byKey(const Key('card2'))).dy, 166);
    expect(tester.getSize(find.byKey(const Key('card2'))).width, 1024);
    await render(
        tester, const Size(1024, 1366), ResponsiveCardGrid(children: children),
        scale: 2);
    expect(tester.getTopLeft(find.byKey(const Key('card1'))).dy, 166);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'tablet setting rows preserve long names and values at enlarged text',
      (tester) async {
    var edited = 0;
    await render(
        tester,
        const Size(1024, 900),
        SizedBox(
            width: 460,
            child: SettingRow(
              name: 'Rear tire pressure on rough terrain',
              value: '3.0',
              unit: 'bar',
              iconAsset: kFieldMeta['Pressure']!.iconAsset,
              onTap: () => edited++,
            )),
        scale: 2);
    expect(find.text('3.0 bar'), findsOneWidget);
    await tester.tap(find.text('Rear tire pressure on rough terrain'));
    expect(edited, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single service card fills its group', (tester) async {
    await render(
        tester,
        const Size(1024, 1366),
        const ResponsiveCardGrid(
            children: [SizedBox(key: Key('single'), height: 150)]));
    expect(tester.getSize(find.byKey(const Key('single'))).width, 1024);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings frame stays centered and bounded', (tester) async {
    await render(
        tester,
        const Size(1366, 1024),
        const AppContentFrame(
            maxWidth: 700, child: SizedBox(key: Key('content'), height: 400)));
    expect(tester.getSize(find.byKey(const Key('content'))).width, 700);
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dx, 333);
  });
  for (final size in [
    const Size(1366, 1024),
    const Size(1024, 1366),
    const Size(390, 844),
    const Size(600, 500)
  ]) {
    testWidgets('sign-in fits $size at normal and enlarged text',
        (tester) async {
      for (final scale in [1.0, 2.0]) {
        await render(tester, size, const LoginPage(), scale: scale);
        expect(find.text('Bike Setup'), findsOneWidget);
        expect(tester.getSize(find.byType(ElevatedButton).first).width,
            lessThanOrEqualTo(400));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
