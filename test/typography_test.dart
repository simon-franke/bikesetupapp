import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_error_banner.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_component_card.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:bikesetupapp/features/workspace/ui/view_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    // Exercise real glyph widths, rather than the widget-test fallback font.
    await (FontLoader('Sora')
          ..addFont(rootBundle.load('assets/fonts/Sora.ttf')))
        .load();
  });
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'detail header wraps and keeps controls usable at $width / $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var opened = false;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
              builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (context) => Scaffold(
                                        appBar: buildDetailAppBar(context,
                                            title: 'Brake Bleeding',
                                            actions: [
                                              IconButton(
                                                  tooltip: 'Options',
                                                  onPressed: () =>
                                                      opened = true,
                                                  icon: const Icon(
                                                      Icons.more_horiz))
                                            ]),
                                        body: const Text('Service details'),
                                      )),
                            ),
                        child: const Text('Open')),
                  )),
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final title = tester.getRect(find.text('Brake Bleeding'));
        final toolbar = tester.getRect(find.byType(AppBar));
        expect(title.bottom, lessThanOrEqualTo(toolbar.bottom));
        expect(title.right,
            lessThanOrEqualTo(tester.getRect(find.byTooltip('Options')).left));
        await tester.tap(find.byTooltip('Options'));
        expect(opened, isTrue);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('Service details'), findsNothing);
      });
      testWidgets('bundled typography stays usable at $width / $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var saved = false;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            appBar: AppBar(title: const Text('Tires')),
            bottomNavigationBar:
                ViewToggle(activeView: ActiveView.setup, onChanged: (_) {}),
            body: SingleChildScrollView(
              child: Column(children: [
                ServiceComponentCard(
                    component: ServiceComponent(
                        id: 'fork',
                        bikeId: 'bike',
                        type: ComponentType.forkServiceLower,
                        name: 'Fork lower leg service',
                        serviceIntervalKm: 2000,
                        createdAt: DateTime(2026, 1)),
                    currentMileageKm: 1200,
                    onTap: () {}),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const AppErrorBanner(message: 'Could not save. Try again.'),
                    const SizedBox(height: 24),
                    SettingValueEditor(
                        initialValue: 24,
                        min: 10,
                        max: 80,
                        step: 1,
                        decimals: 0,
                        unitLabel: 'psi',
                        onChanged: (_) {}),
                    AppActionButton(
                        label: 'Save', onPressed: () => saved = true),
                  ]),
                ),
              ]),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(saved, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
