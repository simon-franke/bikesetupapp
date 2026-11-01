import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tactile button depresses, cancels, activates once and disables',
      (tester) async {
    var count = 0;
    Future<void> mount({bool enabled = true}) => tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
              body: SizedBox(
                  width: 300,
                  child: AppTactileButton(
                      onPressed: enabled ? () => count++ : null,
                      child: const Text('Save')))),
        ));
    await mount();
    expect(tester.getSize(find.byType(ElevatedButton)).width, 300);
    final resting = tester.getTopLeft(find.byType(ElevatedButton));
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Save')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(ElevatedButton)).dy, resting.dy + 6);
    expect(count, 0);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(ElevatedButton)), resting);
    expect(count, 0);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(tester.getTopLeft(find.byType(ElevatedButton)).dy, resting.dy + 6);
    expect(count, 0);
    await tester.pumpAndSettle();
    expect(count, 1);
    await mount(enabled: false);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(count, 1);
    expect(tester.takeException(), isNull);
  });
}
