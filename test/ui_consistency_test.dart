import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'dart:io';

import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/ui/quick_bike_sheet.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
import 'package:bikesetupapp/features/strava/ui/bike_matching_page.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import 'package:bikesetupapp/features/setups/ui/setting_display.dart';
import 'package:bikesetupapp/features/setups/ui/setup_category_view.dart';
import 'package:bikesetupapp/features/setups/ui/setup_overview.dart';
import 'package:bikesetupapp/features/tests/models/setup_test.dart';
import 'package:bikesetupapp/features/tests/ui/tests_view.dart';
import 'package:bikesetupapp/features/tests/ui/track_time_sheet.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_controls.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_repositories.dart';
import 'support/fake_tests_repository.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'user';
}

void main() {
  final output = Platform.environment['UI_REVIEW_OUTPUT'];
  setUpAll(() async {
    for (final font in {
      'Sora': 'assets/fonts/Sora.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  test('measurement labels normalize legacy units and preserve free text', () {
    expect(settingDisplayValue('Pressure', '24'), '24 psi');
    expect(settingDisplayValue('Pressure', '1.5 bar'), '1.5 bar');
    expect(settingDisplayValue('Lever angle', '30 deg'), '30.0 °');
    expect(
        settingDisplayValue('Serial', '00123',
            familyOverride: UnitFamily.freeText),
        '00123');
    expect(settingDisplayValue('Tire', 'Magic Mary'), 'Magic Mary');
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('setup and experiment hierarchy fits dark=$dark scale=$scale',
          (tester) async {
        tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final setups = FakeSetupsRepository()
          ..settings.addAll({
            'bike/setup/FrontTire/Pressure': '24',
            'bike/setup/RearTire/Pressure': '26 psi',
            'bike/setup/Fork/Pressure': '93 psi',
            'bike/setup/Fork/Compression': '0 clicks',
            'bike/setup/Fork/Rebound': '17 clicks',
            'bike/setup/Fork/Notes': 'Long travel fork with a custom tune',
            'bike/setup/Shock/Pressure': '152 psi',
            'bike/setup/Shock/Rebound': '4 clicks',
            'bike/setup/GeneralSettings/Reach': '486 mm',
          });
        final experiments = MemoryTests()
          ..records['experiment'] = SetupTest(
              setupInformation: const {},
              id: 'experiment',
              name: 'More front grip',
              stage: TestStage.ride,
              before: {
                'FrontTire': {'Pressure': '24'}
              },
              values: {
                'FrontTire': {'Pressure': '28 psi'}
              });
        final deps = AppDependencies(
            bikesRepository: (_) => FakeBikesRepository()
              ..bikes = [const Bike(id: 'bike', name: 'Canyon Spectral CF')],
            stravaRepository: FakeStravaRepository(),
            stravaBikesRepository: (_) => FakeStravaBikesRepository()
              ..bikes = [
                const StravaBike(
                    stravaGearId: 'gear',
                    name: 'Canyon Spectral CF',
                    distanceMeters: 12345678),
              ],
            setupsRepository: (_) => setups,
            testsRepository: (_) => experiments);
        addTearDown(deps.dispose);
        addTearDown(experiments.updates.close);

        Future<void> mount(Widget child) async {
          await tester.pumpWidget(ProviderForReview(
              dependencies: deps, dark: dark, scale: scale, child: child));
          await tester.pumpAndSettle();
        }

        Future<void> capture(String name) async {
          expect(tester.takeException(), isNull);
          if (output != null) {
            await expectLater(find.byKey(const ValueKey('review-screen')),
                matchesGoldenFile(Uri.file('$output/$name-$dark-$scale.png')));
          }
        }

        await mount(Scaffold(
            body: SetupOverview(
                configuration: SetupConfiguration(kDefaultFieldKeys),
                user: _User(),
                bike: 'bike',
                setup: 'setup',
                onCategory: (_) {})));
        expect(find.textContaining('Compression  0 clicks', findRichText: true),
            findsOneWidget);
        await capture('overview');

        await mount(Scaffold(
            appBar: AppBar(title: const Text('Fork')),
            body: SetupCategoryView(
                configuration: SetupConfiguration(kDefaultFieldKeys),
                user: _User(),
                bike: 'bike',
                setup: 'setup',
                category: 'Fork')));
        expect(find.text('Fork'), findsOneWidget);
        expect(find.text('93 psi'), findsOneWidget);
        expect(tester.getTopLeft(find.text('93 psi')).dx,
            tester.getTopLeft(find.text('Pressure')).dx);
        expect(tester.getTopLeft(find.text('93 psi')).dy,
            greaterThan(tester.getBottomLeft(find.text('Pressure')).dy));
        await capture('fork');
        await tester.tap(find.text('Pressure'));
        await tester.pumpAndSettle();
        expect(find.text('Delete field'), findsNothing);
        expect(find.byTooltip('Setting options'), findsOneWidget);
        await capture('pressure-editor');
        final zoomRuler = find.byKey(const ValueKey('zoomable-ruler'));
        await tester.ensureVisible(zoomRuler);
        await tester.pumpAndSettle();
        final center = tester.getCenter(zoomRuler);
        final left =
            await tester.startGesture(center - const Offset(60, 0), pointer: 1);
        final right =
            await tester.startGesture(center + const Offset(60, 0), pointer: 2);
        await tester.pump();
        await left.moveTo(center - const Offset(20, 0));
        await right.moveTo(center + const Offset(20, 0));
        await tester.pump();
        await left.up();
        await right.up();
        await tester.pumpAndSettle();
        await capture('pressure-editor-zoomed-out');
        for (var i = 0; i < 4; i++) {
          final first = await tester.startGesture(center - const Offset(30, 0),
              pointer: 1);
          final second = await tester.startGesture(center + const Offset(30, 0),
              pointer: 2);
          await tester.pump();
          await first.moveTo(center - const Offset(60, 0));
          await second.moveTo(center + const Offset(60, 0));
          await tester.pump();
          await first.up();
          await second.up();
          await tester.pumpAndSettle();
        }
        await capture('pressure-editor-zoomed-in');

        // Dispose the previous Navigator with its open sheet before mounting
        // the next independent flow.
        await tester.pumpWidget(const SizedBox());
        await mount(const Scaffold(
            body: TestsView(
                uid: 'user',
                bike: 'bike',
                setup: 'setup',
                setupName: 'Baseline')));
        expect(find.text('Try a new setup'), findsNothing);
        expect(tester.getTopLeft(find.text('More front grip')).dy,
            lessThan(tester.getTopLeft(find.text('Create experiment')).dy));
        await capture('experiments');
        await tester.tap(find.text('More front grip'));
        await tester.pumpAndSettle();
        expect(find.text('24 psi'), findsOneWidget);
        expect(find.text('28 psi'), findsOneWidget);
        await capture('comparison');

        for (final stage in [TestStage.review, TestStage.finished]) {
          final experiment = experiments.records['experiment']!.copyWith(
              stage: stage,
              rides: const [
                RideFeedback(
                    feeling: 'Better',
                    note: 'More grip on loose turns',
                    time: '03:42.156')
              ],
              result: 'Settings applied');
          experiments.records['experiment'] = experiment;
          await tester.pumpWidget(const SizedBox());
          await mount(TestsView(
              uid: 'user',
              bike: 'bike',
              setup: 'setup',
              setupName: 'Baseline',
              initialTest: experiment));
          await capture('experiment-${stage.name}');
          if (stage == TestStage.review) {
            await tester.scrollUntilVisible(
                find.text('Finish experiment').hitTestable(), 250);
            await tester.tap(find.text('Finish experiment'));
            await tester.pumpAndSettle();
            await capture('experiment-outcome');
          }
        }

        await tester.pumpWidget(const SizedBox());
        await mount(BikeMatchingPage(user: _User()));
        await capture('strava-matching');

        for (final preview in <String, Widget>{
          'track-time': const TrackTimeSheet(initial: '03:42.156'),
          'service-interval':
              const ServiceIntervalSheet(initial: 3000, hours: false),
        }.entries) {
          await tester.pumpWidget(const SizedBox());
          await mount(
              Scaffold(body: SingleChildScrollView(child: preview.value)));
          if (preview.key == 'track-time') {
            final milliseconds = find.byKey(const ValueKey('ms'));
            expect(tester.getTopLeft(milliseconds).dx, greaterThanOrEqualTo(0));
            expect(tester.getTopRight(milliseconds).dx,
                lessThanOrEqualTo(tester.view.physicalSize.width));
          }
          await capture(preview.key);
        }

        await tester.pumpWidget(const SizedBox());
        await mount(Scaffold(
            body: QuickBikeSheet(
                user: _User(),
                isSheet: false,
                onCreated: (_, __, ___, ____, configuration) {})));
        await capture('first-bike');
        if (scale == 2) {
          await tester.enterText(find.byType(TextField), 'Trail bike');
          expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              'Trail bike');
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

class ProviderForReview extends StatelessWidget {
  const ProviderForReview(
      {super.key,
      required this.dependencies,
      required this.dark,
      required this.scale,
      required this.child});
  final AppDependencies dependencies;
  final bool dark;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) => Provider.value(
      value: dependencies,
      child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 44, bottom: 24)),
              child: RepaintBoundary(
                  key: const ValueKey('review-screen'), child: child!)),
          home: child));
}
