import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mount(WidgetTester tester, ValueChanged<double> onChanged,
      {bool reduced = false,
      VoidCallback? onTap,
      double initial = 24,
      double step = 0.5,
      int decimals = 1}) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
            body: Center(
                child: SizedBox(
          width: 320,
          child: SettingValueEditor(
              initialValue: initial,
              min: 0,
              max: 100,
              step: step,
              decimals: decimals,
              unitLabel: 'psi',
              onChanged: onChanged,
              onValueTap: onTap),
        ))),
      ),
    ));
  }

  testWidgets('flick coasts then snaps to a valid half-step', (tester) async {
    var value = 24.0;
    await mount(tester, (v) => value = v);
    final ruler = find.byType(SingleChildScrollView);
    await tester.fling(ruler, const Offset(-80, 0), 700);
    await tester.pump();
    final released = value;
    await tester.pump(const Duration(milliseconds: 100));
    expect(value, greaterThan(released));
    await tester.pumpAndSettle();
    expect(value * 2, (value * 2).roundToDouble());
    expect(value, inInclusiveRange(0, 100));
    final position = tester.widget<SingleChildScrollView>(ruler).controller!;
    expect(position.offset / 12,
        closeTo((position.offset / 12).roundToDouble(), 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('changed digits animate and direct entry stays available',
      (tester) async {
    var tapped = false;
    await mount(tester, (_) {}, onTap: () => tapped = true);
    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-48, 0));
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byType(ImageFiltered), findsWidgets);
    await tester.pumpAndSettle();
    for (final filter
        in tester.widgetList<ImageFiltered>(find.byType(ImageFiltered))) {
      expect(filter.enabled, isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion removes rolling and blur', (tester) async {
    var value = 24.0;
    await mount(tester, (v) => value = v, reduced: true);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-48, 0));
    await tester.pumpAndSettle();
    expect(value, greaterThan(24));
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(find.byType(ImageFiltered), findsNothing);
    expect(tester.takeException(), isNull);
  });
  Future<void> pinch(WidgetTester tester, double factor) async {
    final center =
        tester.getCenter(find.byKey(const ValueKey('zoomable-ruler')));
    final first =
        await tester.startGesture(center - const Offset(60, 0), pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(60, 0), pointer: 2);
    await tester.pump();
    await first.moveTo(center - Offset(60 * factor, 0));
    await second.moveTo(center + Offset(60 * factor, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
  }

  testWidgets('pinching changes scale without changing the selected value',
      (tester) async {
    final values = <double>[];
    await mount(tester, values.add);
    final ruler = find.byType(SingleChildScrollView);
    final before = tester
        .widget<SingleChildScrollView>(ruler)
        .controller!
        .position
        .maxScrollExtent;
    await pinch(tester, 2);
    final after = tester
        .widget<SingleChildScrollView>(ruler)
        .controller!
        .position
        .maxScrollExtent;
    expect(after, closeTo(before * 2, 0.1));
    expect(values, isEmpty);
    await tester.drag(ruler, const Offset(-72, 0));
    await tester.pumpAndSettle();
    expect(values, isNotEmpty);
    expect(values.last * 2, values.last * 2 ~/ 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zooming out increases travel for the same drag', (tester) async {
    var value = 24.0;
    await mount(tester, (v) => value = v, reduced: true);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-96, 0));
    await tester.pumpAndSettle();
    final normalChange = value - 24;
    await tester.pumpWidget(const SizedBox());
    await mount(tester, (v) => value = v, reduced: true);
    value = 24;
    await pinch(tester, 0.5);
    expect(value, 24);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-96, 0));
    await tester.pumpAndSettle();
    expect(value - 24, greaterThan(normalChange));
    expect(tester.takeException(), isNull);
  });

  testWidgets('zoom limits preserve boundary values and whole clicks',
      (tester) async {
    final changes = <double>[];
    await mount(tester, changes.add,
        initial: 100, step: 1, decimals: 0, reduced: true);
    for (var i = 0; i < 4; i++) {
      await pinch(tester, 0.5);
    }
    expect(changes, isEmpty);
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(scroll.position.maxScrollExtent, closeTo(300, 0.01));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(changes, isNotEmpty);
    expect(changes.every((value) => value == value.roundToDouble()), isTrue);
    expect(tester.takeException(), isNull);
  });
}
