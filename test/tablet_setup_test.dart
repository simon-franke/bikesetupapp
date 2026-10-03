import 'dart:async';

import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/widgets/control_panel_grid.dart';
import 'package:bikesetupapp/widgets/inline_setting_editor.dart';
import 'package:bikesetupapp/widgets/setting_value_editor.dart';
import 'package:bikesetupapp/widgets/unit_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> render(WidgetTester tester, Widget child,
    {double scale = 1, Size size = const Size(480, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
          data:
              MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: child))));
  await tester.pumpAndSettle();
}

Future<void> moveRuler(WidgetTester tester, int ticks) async {
  final ruler = find.descendant(
      of: find.byType(SettingValueEditor),
      matching: find.byType(SingleChildScrollView));
  final controller = tester.widget<SingleChildScrollView>(ruler).controller!;
  controller.jumpTo(controller.offset + ticks * 12);
  await tester.pump();
}

void main() {
  testWidgets('tiles select the pinned editor and remember each part',
      (tester) async {
    String scope = 'bike/setup/FrontTire';
    Map<String, String> settings = {
      'Pressure': '3.0 bar',
      'Tire width': '40 mm'
    };
    late StateSetter update;
    await render(tester, StatefulBuilder(builder: (context, setState) {
      update = setState;
      return TabletSettingsPanel(
          scope: scope,
          title: scope,
          settings: settings,
          onAdd: () {},
          onSave: (_, __) async {});
    }));
    expect(
        tester
            .widget<InlineSettingEditor>(find.byType(InlineSettingEditor))
            .name,
        'Pressure');
    await tester.tap(find.byKey(const ValueKey('tablet-tile-Tire width')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<InlineSettingEditor>(find.byType(InlineSettingEditor))
            .name,
        'Tire width');
    update(() {
      scope = 'bike/setup/GeneralSettings';
      settings = {'Reach': '432 mm'};
    });
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<InlineSettingEditor>(find.byType(InlineSettingEditor))
            .name,
        'Reach');
    update(() {
      scope = 'bike/setup/FrontTire';
      settings = {'Pressure': '3.0 bar', 'Tire width': '40 mm'};
    });
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<InlineSettingEditor>(find.byType(InlineSettingEditor))
            .name,
        'Tire width');
    update(() {
      settings = {'Pressure': '3.0 bar'};
    });
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<InlineSettingEditor>(find.byType(InlineSettingEditor))
            .name,
        'Pressure');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'successive ruler saves stay ordered without losing the latest value',
      (tester) async {
    final saves = <String>[];
    final first = Completer<void>();
    await render(
        tester,
        InlineSettingEditor(
            name: 'Pressure',
            value: '3.0 bar',
            onSave: (value) async {
              saves.add(value);
              if (saves.length == 1) await first.future;
            }));
    await moveRuler(tester, 1);
    await moveRuler(tester, 1);
    expect(saves, ['3.1 bar']);
    expect(find.text('3.2'), findsOneWidget);
    first.complete();
    await tester.pumpAndSettle();
    expect(saves, ['3.1 bar', '3.2 bar']);
    expect(find.text('Save'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'stream echoes preserve a drag and unit changes save automatically',
      (tester) async {
    final saves = <String>[];
    late StateSetter update;
    var value = '3.0 bar';
    await render(tester, StatefulBuilder(builder: (context, setState) {
      update = setState;
      return InlineSettingEditor(
          name: 'Pressure',
          value: value,
          onSave: (value) async => saves.add(value));
    }));
    expect(find.byTooltip('Increase Pressure'), findsNothing);
    tester
        .widget<SettingValueEditor>(find.byType(SettingValueEditor))
        .onChanged(3.2);
    await tester.pump();
    expect(saves, isEmpty);
    update(() => value = '2.5 bar');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<SettingValueEditor>(find.byType(SettingValueEditor))
            .initialValue,
        3.2);
    await tester.tap(find.text('psi').first);
    await tester.pumpAndSettle();
    expect(find.text('46'), findsOneWidget);
    expect(saves, ['46 psi']);
    expect(find.text('Save'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a ruler gesture saves once after scrolling settles',
      (tester) async {
    final saves = <String>[];
    await render(
        tester,
        InlineSettingEditor(
            name: 'Pressure',
            value: '3.0 bar',
            onSave: (value) async => saves.add(value)));
    final ruler = find.descendant(
        of: find.byType(SettingValueEditor),
        matching: find.byType(SingleChildScrollView));
    await tester.drag(ruler, const Offset(-72, 0));
    await tester.pumpAndSettle();
    expect(saves, hasLength(1));
    expect(saves.single, isNot('3.0 bar'));
    expect(find.text('Save'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap the ruler value to type and save precisely', (tester) async {
    final saves = <String>[];
    await render(
        tester,
        InlineSettingEditor(
            name: 'Pressure',
            value: '3.0 bar',
            onSave: (value) async => saves.add(value)));
    await tester.tap(find.text('3.0'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3,4');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(saves, ['3.4 bar']);
    expect(find.text('3.4'), findsOneWidget);
    expect(find.byType(SettingValueEditor), findsOneWidget);
  });

  testWidgets('reselecting a field shares its pending write queue',
      (tester) async {
    final saves = <String>[];
    final first = Completer<void>();
    await render(
        tester,
        TabletSettingsPanel(
            scope: 'front',
            title: 'Front tire',
            settings: const {'Pressure': '3.0 bar', 'Width': '40 mm'},
            onAdd: () {},
            onSave: (key, value) async {
              saves.add('$key=$value');
              if (saves.length == 1) await first.future;
            }));
    await moveRuler(tester, 1);
    await moveRuler(tester, 1);
    await tester.tap(find.byKey(const ValueKey('tablet-tile-Width')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tablet-tile-Pressure')));
    await tester.pump();
    await moveRuler(tester, -1);
    expect(saves, ['Pressure=3.1 bar']);
    first.complete();
    await tester.pumpAndSettle();
    expect(saves, ['Pressure=3.1 bar', 'Pressure=3.2 bar', 'Pressure=2.9 bar']);
  });

  testWidgets('a failed save retains the draft and supports retry',
      (tester) async {
    var fail = true;
    final saves = <String>[];
    await render(
        tester,
        InlineSettingEditor(
            name: 'Pressure',
            value: '3.0 bar',
            onSave: (value) async {
              if (fail) throw StateError('offline');
              saves.add(value);
            }));
    await moveRuler(tester, 1);
    await tester.pumpAndSettle();
    expect(find.text('3.1'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(saves, ['3.1 bar']);
  });

  testWidgets('text metadata keeps numeric-looking text as text',
      (tester) async {
    final saves = <String>[];
    await render(
        tester,
        InlineSettingEditor(
            name: 'Serial',
            value: '0123',
            familyOverride: UnitFamily.freeText,
            onSave: (value) async => saves.add(value)));
    expect(find.byTooltip('Increase Serial'), findsNothing);
    await tester.enterText(find.byType(TextField), '00456');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(saves, ['00456']);
  });

  testWidgets('tablet panel remains usable at enlarged text and short height',
      (tester) async {
    for (final scale in [1.0, 2.0]) {
      await render(
          tester,
          TabletSettingsPanel(
              scope: 'front',
              title: 'Front tire settings',
              settings: const {
                'Pressure': '3.0 bar',
                'Notes': 'A long trail description'
              },
              onAdd: () {},
              onSave: (_, __) async {}),
          scale: scale,
          size: const Size(360, 500));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('tablet-tile-Notes')), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const ValueKey('tablet-tile-Notes')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<InlineSettingEditor>(find.byType(InlineSettingEditor))
              .name,
          'Notes');
      expect(tester.takeException(), isNull);
    }
  });
}
