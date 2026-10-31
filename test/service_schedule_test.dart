import 'package:bikesetupapp/features/rides/models/ride.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/strava/ui/mileage_banner.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_component_card.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_components_list.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ServiceComponent component(String id, {int interval = 1000}) =>
    ServiceComponent(
      id: id,
      bikeId: 'bike',
      type: ComponentType.chain,
      name: id,
      serviceIntervalKm: interval,
      createdAt: DateTime(2026),
    );

AnnotatedService service(String id, double mileage, {bool known = true}) =>
    annotateService(
      component: component(id),
      currentMileageKm: mileage,
      latestEntry: ServiceEntry(
          id: id, componentId: id, date: DateTime(2026), mileageAtServiceKm: 0),
      mileageAvailable: known,
    );

Widget harness(Widget child, {double scale = 1}) => MaterialApp(
      theme: ThemeData(extensions: const [AppPalette.dark]),
      home: Scaffold(
          body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
                width: 320, child: SingleChildScrollView(child: child))),
      )),
    );

void main() {
  test('remaining mileage is not mislabeled due at the warning threshold', () {
    final warning = service('warning', 900);
    expect(warning.status, ServiceStatus.red);
    expect(serviceDistanceLabel(warning), 'Service in 100 km');
    expect(serviceDistanceLabel(service('due', 1000)), 'Service due now');
    expect(serviceDistanceLabel(service('overdue', 1250)), '250 km overdue');
  });

  test(
      'missing mileage and invalid intervals do not report a healthy component',
      () {
    expect(service('unknown', 0, known: false).status, ServiceStatus.unknown);
    expect(
        annotateService(
                component: component('no-baseline'),
                currentMileageKm: 1000,
                latestEntry: null)
            .status,
        ServiceStatus.unknown);
    expect(
        annotateService(
                component: component('invalid', interval: 0),
                currentMileageKm: 1000,
                latestEntry: null)
            .status,
        ServiceStatus.unknown);
    final entry =
        ServiceEntry(id: 'entry', componentId: 'chain', date: DateTime(2026));
    expect(
        annotateService(
                component: component('chain'),
                currentMileageKm: 1200,
                latestEntry: entry)
            .status,
        ServiceStatus.unknown);
  });

  test('service mileage is measured from the last recorded service', () {
    final entry = ServiceEntry(
        id: 'entry',
        componentId: 'chain',
        date: DateTime(2026),
        mileageAtServiceKm: 500);
    final result = annotateService(
        component: component('chain'),
        currentMileageKm: 1200,
        latestEntry: entry);
    expect(result.usage, 700);
    expect(result.remaining, 300);
    expect(result.status, ServiceStatus.amber);
  });

  test(
      'hour service uses only ride hours and distinguishes missing from empty logs',
      () {
    final date = DateTime(2026);
    final part = ServiceComponent(
        id: 'fork',
        bikeId: 'bike',
        type: ComponentType.forkServiceLower,
        name: 'Fork',
        serviceIntervalKm: 1000,
        serviceIntervalHours: 10,
        createdAt: date);
    final entry = ServiceEntry(
        id: 'service',
        componentId: 'fork',
        date: date,
        mileageAtServiceKm: 500,
        initialRideHours: 2);
    AnnotatedService annotate(List<Ride>? rides) => annotateService(
        component: part,
        currentMileageKm: 99999,
        mileageAvailable: false,
        latestEntry: entry,
        rides: rides);
    final unknown = annotate(null);
    expect(unknown.usageUnknown, isTrue);
    expect(unknown.status, ServiceStatus.unknown);
    final empty = annotate([]);
    expect(empty.measurement.unit, ServiceUnit.hours);
    expect(empty.usageUnknown, isFalse);
    expect(empty.usage, 2);
    expect(empty.remaining, 8);
    final used = annotate([
      Ride(
          id: 'ride',
          bikeId: 'bike',
          startedAt: date,
          durationSeconds: 27000,
          source: 'manual')
    ]);
    expect(used.usage, 9.5);
    expect(used.remaining, .5);
    expect(used.progress, .95);
    expect(used.status, ServiceStatus.red);
    expect(serviceDistanceLabel(used), 'Service in 0.5 ride hours');
  });

  testWidgets('schedule groups urgency without hiding any components',
      (tester) async {
    final services = [
      service('later', 200),
      service('soon', 750),
      service('warning', 950),
      service('overdue', 1400),
      service('unknown', 0, known: false)
    ];
    await tester.pumpWidget(harness(ServiceSchedule(
      services: services,
      cardBuilder: (s) => Text(s.component.id),
    )));
    expect(tester.getTopLeft(find.text('overdue')).dy,
        lessThan(tester.getTopLeft(find.text('warning')).dy));
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Needs a starting point'), findsOneWidget);
    expect(find.text('All (5)'), findsNothing);
    expect(find.text('later'), findsOneWidget);
    expect(find.text('unknown'), findsOneWidget);
    expect(tester.getTopLeft(find.text('soon')).dy,
        lessThan(tester.getTopLeft(find.text('later')).dy));
  });

  testWidgets('the whole service card opens its details', (tester) async {
    var opened = 0;
    await tester.pumpWidget(harness(ServiceComponentCard(
      component: component('Chain'),
      currentMileageKm: 950,
      latestEntry: ServiceEntry(
          id: 'entry',
          componentId: 'Chain',
          date: DateTime(2026),
          mileageAtServiceKm: 0),
      onTap: () => opened++,
    )));
    await tester.tap(find.text('Service in 50 km'));
    expect(opened, 1);
    expect(find.text('Log service'), findsNothing);
  });

  testWidgets('unknown mileage hides progress and deferral; enlarged text fits',
      (tester) async {
    await tester.pumpWidget(harness(
        ServiceComponentCard(
          component: component('A long component model name'),
          currentMileageKm: 0,
          mileageAvailable: false,
          onTap: () {},
        ),
        scale: 2));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Defer service'), findsNothing);
    expect(find.text('Log service'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'sync is disabled while loading and unavailable mileage is explicit',
      (tester) async {
    var synced = 0;
    await tester.pumpWidget(harness(
        MileageBanner(
          mileageKm: null,
          isConnected: true,
          isLoading: true,
          onSync: () => synced++,
        ),
        scale: 2));
    expect(find.text('Not available'), findsOneWidget);
    await tester.tap(find.text('Syncing'));
    expect(synced, 0);
    expect(tester.takeException(), isNull);
  });
}
