import 'package:bikesetupapp/features/maintenance/models/service_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/ui/component_detail_page.dart';
import 'package:bikesetupapp/features/rides/models/ride.dart';
import 'package:bikesetupapp/features/rides/repositories/rides_repository.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/repositories/maintenance_repository.dart';
import 'package:bikesetupapp/features/maintenance/ui/add_component_flow.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Repository extends Fake implements MaintenanceRepository {
  List<ServiceComponent> existing = [];
  @override
  Stream<List<ServiceComponent>> getComponentsForBike(String bikeId) =>
      Stream.value(existing.where((item) => item.bikeId == bikeId).toList());
  ServiceComponent? component;
  ServiceEntry? baseline;
  ServiceEntry? logged;
  double? updatedHours;
  int? updatedKm;
  @override
  Stream<List<ServiceEntry>> getEntriesForComponent(String id) => Stream.value([
        ServiceEntry(
            id: 'entry',
            componentId: id,
            date: DateTime(2026),
            mileageAtServiceKm: 500,
            initialRideHours: 4,
            note: 'Initial setup'),
      ]);
  @override
  Future<void> updateComponent(String id,
      {String? name,
      int? serviceIntervalKm,
      double? serviceIntervalHours}) async {
    updatedHours = serviceIntervalHours;
    updatedKm = serviceIntervalKm;
  }

  @override
  Future<void> addServiceEntry(String id, ServiceEntry entry) async {
    logged = entry;
  }

  @override
  Future<void> createComponentWithBaseline(
      ServiceComponent value, ServiceEntry entry) async {
    component = value;
    baseline = entry;
  }
}

class _User extends Fake implements User {
  @override
  String get uid => 'user';
}

class _Rides extends Fake implements RidesRepository {
  @override
  Stream<List<Ride>> watch(String bikeId) => Stream.value([]);
}

void main() {
  testWidgets(
      'component picker hides tracked presets but keeps custom creation',
      (tester) async {
    final repo = _Repository()
      ..existing = [
        ServiceComponent(
            id: 'chain',
            bikeId: 'bike',
            type: ComponentType.chain,
            name: 'Renamed chain',
            serviceIntervalKm: 2000,
            createdAt: DateTime(2026)),
        ServiceComponent(
            id: 'custom',
            bikeId: 'bike',
            type: ComponentType.other,
            name: 'Dropper',
            serviceIntervalKm: 1000,
            createdAt: DateTime(2026)),
        ServiceComponent(
            id: 'rear',
            bikeId: 'another-bike',
            type: ComponentType.brakePadsRear,
            name: 'Rear pads',
            serviceIntervalKm: 1000,
            createdAt: DateTime(2026)),
      ];
    await tester.pumpWidget(Provider.value(
      value: AppDependencies(maintenanceRepository: (_) => repo),
      child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AddServiceComponentFlow(
              uid: 'user', bikeId: 'bike', currentMileageKm: 0)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Chain'), findsNothing);
    expect(find.text('Brake Pads Rear'), findsOneWidget);
    await tester.ensureVisible(find.text('Add new'));
    await tester.tap(find.text('Add new'));
    await tester.pumpAndSettle();
    expect(find.text('Component details'), findsOneWidget);
  });

  testWidgets('custom component preserves and persists chosen icon',
      (tester) async {
    final repo = _Repository();
    final deps = AppDependencies(maintenanceRepository: (_) => repo);
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => const AddServiceComponentFlow(
                                    uid: 'user',
                                    bikeId: 'bike',
                                    currentMileageKm: 1200))),
                        child: const Text('Open')))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add new'));
    await tester.tap(find.text('Add new'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose icon'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Saddle'));
    await tester.pumpAndSettle();
    expect(find.text('Saddle'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Dropper post');
    await tester.enterText(find.byKey(const ValueKey('already-used')), '250');
    await tester.enterText(
        find.byKey(const ValueKey('service-interval')), '1500');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add new'));
    await tester.tap(find.text('Add new'));
    await tester.pumpAndSettle();
    expect(find.text('Saddle'), findsNothing);
    expect(find.text('Dropper post'), findsOneWidget);
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    expect(repo.component!.customIcon, ServiceIcon.saddle);
    expect(repo.baseline!.initialDistanceKm, 250);
    final restored = ServiceComponent.fromMap('part', repo.component!.toMap());
    expect(restored.customIcon, ServiceIcon.saddle);
    final withoutOptionalField = repo.component!.toMap()..remove('customIcon');
    expect(ServiceComponent.fromMap('part', withoutOptionalField).customIcon, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final hours in [false, true]) {
    testWidgets(
        'service details edit and log ${hours ? 'hours' : 'kilometres'} at large text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repository();
      final deps = AppDependencies(
          maintenanceRepository: (_) => repo, ridesRepository: (_) => _Rides());
      final component = ServiceComponent(
          id: 'part',
          bikeId: 'bike',
          type: ComponentType.chain,
          name: 'Chain',
          serviceIntervalKm: 1000,
          serviceIntervalHours: hours ? 50 : null,
          createdAt: DateTime(2026));
      await tester.pumpWidget(Provider.value(
          value: deps,
          child: MaterialApp(
              theme: AppTheme.darkTheme,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!),
              home: ComponentDetailPage(
                  user: _User(),
                  component: component,
                  currentMileageKm: 600))));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Service interval'));
      await tester.tap(find.text('Service interval'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), hours ? '60.5' : '1500');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      if (hours) {
        expect(repo.updatedHours, 60.5);
      } else {
        expect(repo.updatedKm, 1500);
      }
      expect(find.text(hours ? 'Every 60.5 ride hours' : 'Every 1,500 km'),
          findsOneWidget);
      await tester.tap(find.text('Log service'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Cleaned and inspected');
      final save = find.widgetWithText(ElevatedButton, 'Log service').last;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.logged!.note, 'Cleaned and inspected');
      expect(repo.logged!.initialRideHours, hours ? 0 : null);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      deps.dispose();
    });
  }

  testWidgets(
      'component flow preserves intervals and name across unit and type changes',
      (tester) async {
    final repo = _Repository();
    final deps = AppDependencies(maintenanceRepository: (_) => repo);
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => const AddServiceComponentFlow(
                                    uid: 'user',
                                    bikeId: 'bike',
                                    currentMileageKm: 1200))),
                        child: const Text('Open')))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chain'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose icon'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Cassette'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'My chain');
    await tester.enterText(
        find.byKey(const ValueKey('service-interval')), '1600');
    await tester.tap(find.bySemanticsLabel('Unit: Kilometres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ride hours'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('service-interval')), '50');
    await tester.tap(find.bySemanticsLabel('Unit: Ride hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kilometres'));
    await tester.pumpAndSettle();
    expect(find.text('1600'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Front Tire'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chain'));
    await tester.pumpAndSettle();
    expect(find.text('My chain'), findsOneWidget);
    expect(find.text('1600'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Unit: Kilometres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ride hours'));
    await tester.pumpAndSettle();
    expect(find.text('50'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('already-used')), '');
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    expect(repo.component!.name, 'My chain');
    expect(repo.component!.customIcon, ServiceIcon.cassette);
    expect(repo.component!.serviceIntervalHours, 50);
    expect(repo.baseline!.initialRideHours, 0);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
  });

  testWidgets(
      'interval sheet validates whole kilometres and accepts fractional hours',
      (tester) async {
    for (final hours in [false, true]) {
      double? saved;
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        saved = await Navigator.push<double>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => Scaffold(
                                    body: ServiceIntervalSheet(
                                        initial: 100, hours: hours))));
                      },
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      await tester.enterText(find.byType(TextField), '12.5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      if (hours) {
        expect(saved, 12.5);
      } else {
        expect(saved, isNull);
        expect(
            find.text('Enter the distance between services.'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '1200');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(saved, 1200);
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('guided setup fits a narrow phone with large text and keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(Provider.value(
        value: AppDependencies(maintenanceRepository: (_) => _Repository()),
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    viewInsets: const EdgeInsets.only(bottom: 300)),
                child: child!),
            home: const AddServiceComponentFlow(
                uid: 'user', bikeId: 'bike', currentMileageKm: null))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Chain'));
    await tester.tap(find.text('Chain'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('service-interval')));
    await tester.enterText(
        find.byKey(const ValueKey('service-interval')), '1000');
    await tester.ensureVisible(find.byKey(const ValueKey('already-used')));
    expect(find.text('Already used'), findsOneWidget);
    expect(find.text('Add component'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
