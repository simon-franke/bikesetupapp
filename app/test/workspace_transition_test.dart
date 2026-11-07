import 'package:bikesetupapp/features/workspace/ui/workspace_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'short Service content stays top-aligned and full-sized throughout tab entry',
      (tester) async {
    var service = false;
    var loaded = false;
    late StateSetter update;
    const pageKey = ValueKey('service-page');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 390,
                height: 500,
                child: StatefulBuilder(builder: (context, setState) {
                  update = setState;
                  return WorkspaceTransition(
                      child: service
                          ? LayoutBuilder(
                              key: pageKey,
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                      child: Column(children: [
                                    const Text('Service'),
                                    SizedBox(height: loaded ? 300 : 40)
                                  ])))
                          : const SizedBox.expand(key: ValueKey('setup')));
                })))));
    update(() => service = true);
    await tester.pump();
    final top = tester.getTopLeft(find.byKey(pageKey));
    for (final milliseconds in [40, 60, 100]) {
      await tester.pump(Duration(milliseconds: milliseconds));
      expect(tester.getSize(find.byKey(pageKey)), const Size(390, 500));
      expect(tester.getTopLeft(find.text('Service')).dy, top.dy);
    }
    update(() => loaded = true);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Service')).dy, top.dy);
    expect(tester.takeException(), isNull);
  });
  testWidgets('returning to a tab retains scroll and inactive tabs ignore taps',
      (tester) async {
    var service = false;
    late StateSetter update;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return WorkspaceTransition(
          child: service
              ? const Center(key: ValueKey('service'), child: Text('Service'))
              : ListView(
                  key: const ValueKey('setup'),
                  controller: scroll,
                  children: List.generate(30,
                      (i) => SizedBox(height: 60, child: Text('Setting $i')))));
    }))));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final offset = scroll.offset;
    update(() => service = true);
    await tester.pumpAndSettle();
    expect(find.text('Setting 8').hitTestable(), findsNothing);
    update(() => service = false);
    await tester.pumpAndSettle();
    expect(scroll.offset, offset);
    expect(tester.takeException(), isNull);
  });
}
