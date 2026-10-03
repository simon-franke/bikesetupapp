import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/bike_enums/component_type.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/mileage_banner.dart';
import 'package:bikesetupapp/widgets/service_component_card.dart';
import 'package:bikesetupapp/widgets/service_components_list.dart';
import 'package:bikesetupapp/widgets/service_status.dart';
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
    expect(result.kmSinceService, 700);
    expect(result.remainingKm, 300);
    expect(result.status, ServiceStatus.amber);
  });

  testWidgets(
      'attention filter prioritizes overdue components and preserves All',
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
    await tester.tap(find.text('Needs attention (4)'));
    await tester.pumpAndSettle();
    expect(find.text('later'), findsNothing);
    expect(find.text('unknown'), findsOneWidget);
    expect(find.text('soon'), findsOneWidget);
    await tester.tap(find.text('All (5)'));
    await tester.pumpAndSettle();
    expect(find.text('later'), findsOneWidget);
    expect(find.text('unknown'), findsOneWidget);
  });

  testWidgets('every card can log service and urgent cards can defer',
      (tester) async {
    var logged = 0;
    var deferred = 0;
    await tester.pumpWidget(harness(ServiceComponentCard(
      component: component('chain'),
      currentMileageKm: 950,
      latestEntry: ServiceEntry(
          id: 'entry',
          componentId: 'chain',
          date: DateTime(2026),
          mileageAtServiceKm: 0),
      onLog: () => logged++,
      onDefer: () => deferred++,
    )));
    await tester.tap(find.text('Log service'));
    await tester.tap(find.text('Defer service'));
    expect(logged, 1);
    expect(deferred, 1);
    await tester.pumpWidget(harness(ServiceComponentCard(
      component: component('chain'),
      currentMileageKm: 100,
      latestEntry: ServiceEntry(
          id: 'entry',
          componentId: 'chain',
          date: DateTime(2026),
          mileageAtServiceKm: 0),
      onLog: () => logged++,
      onDefer: () => deferred++,
    )));
    expect(find.text('Log service'), findsOneWidget);
    expect(find.text('Defer service'), findsNothing);
  });

  testWidgets('unknown mileage hides progress and deferral; enlarged text fits',
      (tester) async {
    await tester.pumpWidget(harness(
        ServiceComponentCard(
          component: component('A long component model name'),
          currentMileageKm: 0,
          mileageAvailable: false,
          onLog: () {},
          onDefer: () {},
        ),
        scale: 2));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Defer service'), findsNothing);
    expect(find.text('Log service'), findsOneWidget);
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
