import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/features/rides/models/ride.dart';
import 'package:bikesetupapp/features/rides/controllers/rides_controller.dart';
import 'package:bikesetupapp/features/rides/repositories/rides_repository.dart';
import 'package:bikesetupapp/features/rides/ui/ride_log_page.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/models/service_schedule.dart';

class _Rides extends Fake implements RidesRepository {
  final saved = <Ride>[];
  @override
  Future<int> insert(List<Ride> rides) async {
    saved.addAll(rides);
    return rides.length;
  }
}

void main() {
  final date = DateTime.utc(2026, 1, 2);
  Ride ride(String id, double km,
          {bool strava = false, bool indoor = false, DateTime? at}) =>
      Ride(
          id: id,
          bikeId: 'bike',
          startedAt: at ?? date,
          durationSeconds: 0,
          source: 'manual',
          distanceKm: km,
          distanceInStrava: strava,
          indoor: indoor);
  final part = ServiceComponent(
      id: 'part',
      bikeId: 'bike',
      type: ComponentType.chain,
      name: 'Chain',
      serviceIntervalKm: 1000,
      createdAt: date);

  test(
      'distance supports local logs and excludes rides covered by Strava mileage',
      () {
    final rides = [
      ride('local', 30),
      ride('strava', 70, strava: true),
      ride('old', 200, at: date.subtract(const Duration(days: 1))),
      ride('indoor', 100, indoor: true)
    ];
    final baseline = ServiceEntry(
        id: 'entry',
        componentId: 'part',
        date: date,
        mileageAtServiceKm: 500,
        initialDistanceKm: 200);
    final linked = annotateService(
        component: part,
        currentMileageKm: 570,
        latestEntry: baseline,
        rides: rides);
    expect(linked.usage, 300);
    expect(linked.remaining, 700);
    final local = annotateService(
        component: part,
        currentMileageKm: 0,
        mileageAvailable: false,
        latestEntry: baseline,
        rides: rides);
    expect(local.usage, 300);
    expect(local.usageUnknown, isFalse);
    final reset = annotateService(
        component: part,
        currentMileageKm: 570,
        latestEntry: ServiceEntry(
            id: 'reset',
            componentId: 'part',
            date: date.add(const Duration(days: 1)),
            mileageAtServiceKm: 570),
        rides: rides);
    expect(reset.usage, 0);
    final removed = annotateService(
        component: part,
        currentMileageKm: 570,
        latestEntry: baseline,
        rides: rides.where((r) => r.id != 'local').toList());
    expect(removed.usage, 270);
    expect(
        ServiceEntry.fromMap('entry', baseline.toMap()).initialDistanceKm, 200);
  });

  test('distance-only rides persist and invalid/empty values never write',
      () async {
    final repo = _Rides();
    final controller = RidesController(repo);
    addTearDown(controller.dispose);
    final value = ride('valid', 42.5, strava: true);
    expect((await controller.save([value])).isSuccess, isTrue);
    final restored = Ride.fromMap('valid', value.toMap()).forBike('other');
    expect(restored.distanceKm, 42.5);
    expect(restored.distanceInStrava, isTrue);
    for (final km in [0.0, -1.0, double.nan, double.infinity]) {
      expect((await controller.save([ride('invalid', km)])).isSuccess, isFalse);
    }
    expect(repo.saved.length, 1);
    final legacy = Ride.fromMap(
        'legacy',
        Ride(
                id: 'legacy',
                bikeId: 'bike',
                startedAt: date,
                durationSeconds: 3600,
                source: 'manual')
            .toMap()
          ..remove('distanceInStrava'));
    expect(legacy.distanceKm, isNull);
    expect(legacy.distanceInStrava, isFalse);
  });

  for (final mode in ['distance', 'time', 'both']) {
    testWidgets('manual ride accepts $mode and preserves km/mi conversion',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Rides();
      final controller = RidesController(repo);
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showAppSheet<void>(
                          context: context,
                          builder: (_) => ManualRideForm(
                              controller: controller,
                              bikeId: 'bike',
                              bikeName: 'Test')),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      if (mode != 'time') {
        await tester.ensureVisible(find.byKey(const ValueKey('ride-distance')));
        await tester.enterText(
            find.byKey(const ValueKey('ride-distance')), '10');
        await tester.tap(find.bySemanticsLabel('Unit: Kilometres'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Miles'));
        await tester.pumpAndSettle();
        expect(find.text('6.21'), findsOneWidget);
        await tester.ensureVisible(find.text('Already included in Strava'));
        await tester.tap(find.text('Already included in Strava'));
      }
      if (mode != 'distance') {
        await tester.ensureVisible(find.byKey(const ValueKey('ride-minutes')));
        await tester.enterText(
            find.byKey(const ValueKey('ride-minutes')), '45');
      }
      await tester.ensureVisible(find.text('Save ride'));
      await tester.tap(find.text('Save ride'));
      await tester.pumpAndSettle();
      expect(repo.saved, hasLength(1));
      expect(repo.saved.single.durationSeconds, mode == 'distance' ? 0 : 2700);
      expect(repo.saved.single.distanceKm, mode == 'time' ? null : 10);
      expect(repo.saved.single.distanceInStrava, mode != 'time');
      expect(tester.takeException(), isNull);
    });
  }
}
