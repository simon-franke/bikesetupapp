import 'package:bikesetupapp/common/models/command_result.dart';
import 'dart:async';

import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/app/startup/startup_controller.dart';
import 'package:bikesetupapp/features/bikes/controllers/bikes_controller.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/bikes/models/bike_type.dart';
import 'package:bikesetupapp/features/maintenance/controllers/maintenance_controller.dart';
import 'package:bikesetupapp/features/maintenance/controllers/service_entries_controller.dart';
import 'package:bikesetupapp/features/maintenance/controllers/services_controller.dart';
import 'package:bikesetupapp/features/setups/controllers/setups_controller.dart';
import 'package:bikesetupapp/features/setups/controllers/setting_save_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_connection_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_sync_service.dart';
import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
import 'package:bikesetupapp/features/strava/models/strava_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fake_repositories.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('bike creation retains defaults and shock configuration', () async {
    final bikes = FakeBikesRepository();
    final setups = FakeSetupsRepository();
    final setupController = SetupsController(setups);
    final controller = BikesController(bikes, setups);
    final id = await controller
        .createBike('Enduro', {'shock': 'Coil'}, BikeType.enduro.bikeType)
        .orThrow();
    final setupId = setups.defaults[id]!;
    expect(bikes.defaultBike, id);
    expect(bikes.bikes.single.name, 'Enduro');
    expect(setups.names[setupId], 'Default');
    expect(setups.settings['$id/$setupId/Shock/Spring Rate'], '450');
    expect(setups.settings.containsKey('$id/$setupId/Shock/Pressure'), isFalse);
    expect(controller.isBusy, isFalse);
    controller.dispose();
    setupController.dispose();
  });

  test('startup rejects incomplete selections and resolves a complete default',
      () async {
    final bikes = FakeBikesRepository();
    final setups = FakeSetupsRepository();
    final setupController = SetupsController(setups);
    final bikeController = BikesController(bikes, setups);
    final startup = StartupController(bikes, setups);
    expect(await startup.loadSelection(), isNull);
    bikes.defaultBike = 'bike';
    bikes.bikes = [
      Bike(id: 'bike', name: 'Road', bikeType: BikeType.road.bikeType)
    ];
    expect(await startup.loadSelection(), isNull);
    setups.defaults['bike'] = 'setup';
    expect(await startup.loadSelection(), isNull);
    setups.names['setup'] = 'Commute';
    final selected = (await startup.loadSelection())!;
    expect(selected.bikeName, 'Road');
    expect(selected.setupName, 'Commute');
    expect(selected.bikeType, BikeType.road);
    bikeController.dispose();
    setupController.dispose();
  });

  test('setting writes stay ordered per destination while other fields proceed',
      () async {
    final repository = FakeSetupsRepository();
    final gate = Completer<void>();
    final started = <String>[];
    repository.onWrite = (key, value, bike, category, setup) async {
      started.add('$key=$value');
      if (value == 'first') await gate.future;
    };
    final controller = SetupsController(repository);
    final first =
        controller.setSetting('Pressure', 'first', 'bike', 'Fork', 'setup');
    final next =
        controller.setSetting('Pressure', 'next', 'bike', 'Fork', 'setup');
    final other =
        controller.setSetting('Rebound', 'other', 'bike', 'Fork', 'setup');
    await other;
    expect(started, ['Pressure=first', 'Rebound=other']);
    expect(controller.isBusy, isTrue);
    gate.complete();
    await Future.wait([first, next]);
    expect(repository.settings['bike/setup/Fork/Pressure'], 'next');
    expect(controller.isBusy, isFalse);
    controller.dispose();
  });

  test('a failed queued write propagates and does not block the next save',
      () async {
    final repository = FakeSetupsRepository();
    repository.onWrite = (_, value, __, ___, ____) async {
      if (value == 'bad') throw StateError('offline');
    };
    final controller = SetupsController(repository);
    await expectLater(
        controller.setSetting('Pressure', 'bad', 'bike', 'Fork', 'setup'),
        throwsStateError);
    expect(controller.error, isA<StateError>());
    await controller.setSetting('Pressure', 'good', 'bike', 'Fork', 'setup');
    expect(repository.settings['bike/setup/Fork/Pressure'], 'good');
    expect(controller.error, isNull);
    controller.dispose();
  });

  test('editor save revisions ignore older completions and expose retry state',
      () async {
    final controller = SettingSaveController();
    final first = Completer<void>();
    final next = Completer<void>();
    final a = controller.save('a', (_) => first.future);
    final b = controller.save('b', (_) => next.future);
    first.complete();
    await a;
    expect(controller.saving, isTrue);
    next.completeError(const AppFailure(FailureCode.saveFailed));
    await b;
    expect(controller.saving, isFalse);
    expect(controller.failed, isTrue);
    await controller.save('b', (_) async {});
    expect(controller.failed, isFalse);
    controller.dispose();
  });

  test('a save can finish after the editor is disposed without notification',
      () async {
    final controller = SettingSaveController();
    final gate = Completer<void>();
    final save = controller.save('90', (_) => gate.future);
    controller.dispose();
    gate.complete();
    await save;
  });

  test('mileage for an old bike cannot overwrite the current selection',
      () async {
    final repository = FakeStravaBikesRepository();
    final connection = FakeStravaRepository();
    final strava = StravaController(repository, connection);
    final auth = StravaConnectionController(connection);
    final controller = ServicesController(strava, auth, 'old');
    final oldLoad = controller.load();
    await flush();
    final newLoad = controller.selectBike('new');
    await flush();
    repository.mileage['new']!.complete(200);
    await flush();
    repository.mileage['old']!.complete(100);
    expect((await oldLoad).isCancelled, isTrue);
    expect((await newLoad).isSuccess, isTrue);
    expect(controller.mileageKm, 200);
    expect(controller.bikeId, 'new');
    controller.dispose();
    strava.dispose();
    auth.dispose();
  });

  test('service entry subscriptions are replaced, retried and disposed',
      () async {
    final repository = FakeMaintenanceRepository();
    final maintenance = MaintenanceController(repository);
    final controller = ServiceEntriesController(maintenance);
    controller.watch(['old']);
    expect(repository.latest['old']!.hasListener, isTrue);
    controller.watch(['new']);
    expect(repository.latest['old']!.hasListener, isFalse);
    repository.latest['new']!.addError(StateError('offline'));
    await flush();
    expect(controller.hasError, isTrue);
    controller.retry();
    repository.latest['new']!.add(null);
    await flush();
    expect(controller.loading, isFalse);
    expect(controller.hasError, isFalse);
    expect(controller.entries, {'new': null});
    controller.dispose();
    expect(repository.latest['new']!.hasListener, isFalse);
    maintenance.dispose();
    await repository.close();
  });

  test(
      'Strava sync marks success only after persistence and keeps useful failures',
      () async {
    final connection = FakeStravaRepository();
    final repository = FakeStravaBikesRepository();
    final service = StravaSyncService(repository, connection);
    connection.failure = const StravaApiException(FailureCode.rateLimited);
    expect((await service.sync()).failure?.code, FailureCode.rateLimited);
    expect(repository.saves, 0);
    expect(connection.markedSynced, 0);
    connection.failure = null;
    connection.bikes = [
      const StravaBike(
          stravaGearId: 'gear', name: 'Bike', distanceMeters: 123000)
    ];
    expect((await service.sync()).isSuccess, isTrue);
    expect(repository.bikes.single.distanceKm, 123);
    expect(connection.markedSynced, 1);
  });

  testWidgets(
      'Provider scope injects a repository without initializing Firebase',
      (tester) async {
    final repository = FakeSetupsRepository();
    repository.settings['bike/setup/Fork/Pressure'] = '90';
    final dependencies = AppDependencies(setupsRepository: (_) => repository);
    await tester.pumpWidget(Provider<AppDependencies>.value(
      value: dependencies,
      child: MaterialApp(home: Builder(builder: (context) {
        final controller = AppDependencies.of(context).forUser('user').setups;
        return StreamBuilder<Map<String, dynamic>>(
          stream: controller.getSettings('bike', 'Fork', 'setup'),
          builder: (_, snapshot) =>
              Text(snapshot.data?['Pressure']?.toString() ?? 'Loading'),
        );
      })),
    ));
    await tester.pump();
    expect(find.text('90'), findsOneWidget);
    expect(
        identical(dependencies.forUser('user').setups,
            dependencies.forUser('user').setups),
        isTrue);
    await tester.pumpWidget(const SizedBox());
    dependencies.dispose();
  });
}
