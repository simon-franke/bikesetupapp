import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
import 'package:bikesetupapp/features/auth/controllers/auth_controller.dart';
import 'package:bikesetupapp/features/auth/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/maintenance/controllers/maintenance_controller.dart';
import 'package:bikesetupapp/features/maintenance/controllers/service_editor_controller.dart';
import 'package:bikesetupapp/features/maintenance/controllers/service_entries_controller.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/settings/controllers/app_state_notifier.dart';
import 'package:bikesetupapp/features/settings/repositories/theme_preferences_repository.dart';
import 'package:bikesetupapp/features/strava/controllers/bike_matching_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_connection_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import 'package:bikesetupapp/features/bikes/controllers/bikes_controller.dart';
import 'package:bikesetupapp/features/workspace/controllers/workspace_controller.dart';
import 'package:bikesetupapp/features/bikes/models/bike_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_repositories.dart';

class TestCommands extends OperationController {
  Future<CommandResult<T>> execute<T>(Future<T> Function() action) =>
      command(action);
  Future<CommandResult<void>> shared(Future<void> Function() action) =>
      share('write', () => command(action));
}

class ServiceWrites extends FakeMaintenanceRepository {
  final entries = <ServiceEntry>[];
  Future<void> Function()? write;
  @override
  Future<void> addServiceEntry(String id, ServiceEntry entry) async {
    entries.add(entry);
    await write?.call();
  }
}

class Credential extends Fake implements UserCredential {}

class DelayedBikes extends FakeStravaBikesRepository {
  final saveGate = Completer<void>();
  final started = Completer<void>();
  final events = <String>[];
  @override
  Future<void> saveStravaBikes(List<StravaBike> incoming) async {
    events.add('save started');
    started.complete();
    await saveGate.future;
    bikes = incoming;
    events.add('saved');
  }

  @override
  Future<void> deleteAllStravaBikes() async {
    events.add('deleted');
    bikes = [];
  }
}

class AuthWrites implements AuthRepository {
  final events = <String>[];
  final gate = Completer<void>();
  @override
  User? get currentUser => null;
  @override
  Future<UserCredential> signInAnonymously() async {
    events.add('signin');
    await gate.future;
    return Credential();
  }

  @override
  Future<void> signOut() async {
    events.add('signout');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class ThemeWrites implements ThemePreferencesRepository {
  final writes = <String>[];
  final gate = Completer<void>();
  @override
  Future<String?> readTheme() async => null;
  @override
  Future<void> saveTheme(String mode) async {
    writes.add(mode);
    if (writes.length == 1) await gate.future;
  }
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('disconnect invalidates sync and deletes after an already started write',
      () async {
    final bikes = DelayedBikes();
    final connection = FakeStravaRepository()
      ..bikes = [
        const StravaBike(
            stravaGearId: 'gear', name: 'Bike', distanceMeters: 1000)
      ];
    final controller = StravaController(bikes, connection);
    final sync = controller.sync();
    await bikes.started.future;
    final deletion = controller.deleteAllStravaBikes();
    await flush();
    expect(bikes.events, ['save started']);
    bikes.saveGate.complete();
    expect((await sync).isCancelled, isTrue);
    expect((await deletion).isSuccess, isTrue);
    expect(bikes.events, ['save started', 'saved', 'deleted']);
    expect(bikes.bikes, isEmpty);
    expect(connection.markedSynced, 0);
    controller.dispose();
  });

  test(
      'auth commands share duplicate requests and order signout cleanup after signin',
      () async {
    final repository = AuthWrites();
    final auth = AuthController(repository, onSigningOut: () async {
      repository.events.add('cleanup');
    }, onSignedOut: () {
      repository.events.add('disposed user controllers');
    });
    final signin = auth.signInAnonymously();
    final duplicate = auth.signInAnonymously();
    final signout = auth.signOut();
    await flush();
    expect(identical(signin, duplicate), isTrue);
    expect(repository.events, ['signin']);
    repository.gate.complete();
    expect((await signin).isSuccess, isTrue);
    expect((await signout).isSuccess, isTrue);
    expect(repository.events,
        ['signin', 'cleanup', 'signout', 'disposed user controllers']);
    auth.dispose();
  });

  test('an older failure cannot replace the newest command state', () async {
    final controller = TestCommands();
    final old = Completer<void>();
    final pending = controller.execute(() => old.future);
    await controller.execute(() async {});
    old.completeError(const AppFailure(FailureCode.loadFailed));
    expect((await pending).failure?.code, FailureCode.loadFailed);
    expect(controller.error, isNull);
    expect(controller.isBusy, isFalse);
    controller.dispose();
  });

  test(
      'typed failure, cancellation, and unexpected error retain distinct outcomes',
      () async {
    final controller = TestCommands();
    expect((await controller.execute(() async => 42)).requireValue(), 42);
    const failure = AppFailure(FailureCode.saveFailed);
    expect((await controller.execute(() async => throw failure)).failure,
        same(failure));
    expect(controller.failure, same(failure));
    expect(controller.errorStackTrace, isNotNull);
    expect(
        (await controller.execute(() async => throw const CommandAborted()))
            .isCancelled,
        isTrue);
    expect(controller.error, isNull);
    final error = StateError('programming error');
    final stack = StackTrace.fromString('original stack');
    await expectLater(
        controller.execute(() async => Error.throwWithStackTrace(error, stack)),
        throwsA(same(error)));
    expect(controller.error, same(error));
    expect(controller.errorStackTrace.toString(), contains('original stack'));
    controller.dispose();
  });

  test(
      'concurrent identical commands share one write and disposal suppresses notifications',
      () async {
    final controller = TestCommands();
    final gate = Completer<void>();
    var calls = 0;
    var notifications = 0;
    controller.addListener(() => notifications++);
    Future<void> write() {
      calls++;
      return gate.future;
    }

    final first = controller.shared(write);
    final second = controller.shared(write);
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    expect(controller.isBusy, isTrue);
    controller.dispose();
    final before = notifications;
    gate.complete();
    expect((await first).isCancelled, isTrue);
    expect((await second).isCancelled, isTrue);
    expect(notifications, before);
    expect((await controller.shared(write)).isCancelled, isTrue);
    expect(calls, 1);
  });

  test(
      'service save shares duplicate submission and retry preserves id and date',
      () async {
    final repository = ServiceWrites();
    final maintenance = MaintenanceController(repository);
    final connection = StravaConnectionController(FakeStravaRepository());
    final date = DateTime.utc(2026, 1, 2);
    final component = ServiceComponent(
        id: 'component',
        bikeId: 'bike',
        type: ComponentType.values.first,
        name: 'Fork',
        serviceIntervalKm: 1000,
        createdAt: date);
    var ids = 0;
    final editor = ServiceEditorController(maintenance, connection,
        component: component,
        currentMileageKm: 1500,
        newId: () => 'entry-${++ids}',
        now: () => date);
    final gate = Completer<void>();
    repository.write = () => gate.future;
    final first = editor.deferService(300);
    final duplicate = editor.deferService(300);
    expect(identical(first, duplicate), isTrue);
    expect(repository.entries, hasLength(1));
    gate.completeError(const AppFailure(FailureCode.saveFailed));
    expect((await first).failure?.code, FailureCode.saveFailed);
    expect(editor.saveError, isA<AppFailure>());
    expect(editor.saving, isFalse);
    repository.write = null;
    expect((await editor.deferService(300)).isSuccess, isTrue);
    expect(repository.entries.map((e) => e.id), ['entry-1', 'entry-1']);
    expect(repository.entries.map((e) => e.date), [date, date]);
    expect(repository.entries.last.mileageAtServiceKm, 800);
    editor.dispose();
    maintenance.dispose();
    connection.dispose();
    await repository.close();
  });

  test('stream failures retain stack and cannot mutate controller collections',
      () async {
    final repository = FakeMaintenanceRepository();
    final maintenance = MaintenanceController(repository);
    final entries = ServiceEntriesController(maintenance)..watch(['component']);
    final error = StateError('stream failed');
    final stack = StackTrace.fromString('stream stack');
    repository.latest['component']!.addError(error, stack);
    await flush();
    expect(entries.loading, isFalse);
    expect(entries.errors['component']!.$1, same(error));
    expect(entries.errors['component']!.$2, same(stack));
    expect(() => entries.entries['other'] = null, throwsUnsupportedError);
    expect(() => entries.errors.clear(), throwsUnsupportedError);
    entries.dispose();
    maintenance.dispose();
    await repository.close();
  });

  test('matching exposes read-only lists and maps', () async {
    final bikes =
        BikesController(FakeBikesRepository(), FakeSetupsRepository());
    final strava =
        StravaController(FakeStravaBikesRepository(), FakeStravaRepository());
    final matching = BikeMatchingController(bikes, strava);
    expect((await matching.load(syncIfEmpty: false)).isSuccess, isTrue);
    expect(() => matching.links['gear'] = 'bike', throwsUnsupportedError);
    expect(() => matching.appBikes.clear(), throwsUnsupportedError);
    expect(() => matching.stravaBikes.clear(), throwsUnsupportedError);
    matching.dispose();
    bikes.dispose();
    strava.dispose();
  });

  test(
      'theme persistence is ordered and only newest selection updates presentation',
      () async {
    final preferences = ThemeWrites();
    final theme = AppStateNotifier(ThemeMode.dark, preferences: preferences);
    final first = theme.updateTheme(ThemeMode.light);
    final second = theme.updateTheme(ThemeMode.system);
    await flush();
    expect(preferences.writes, ['light']);
    preferences.gate.complete();
    expect((await first).isCancelled, isTrue);
    expect((await second).isSuccess, isTrue);
    expect(preferences.writes, ['light', 'system']);
    expect(theme.themeMode, ThemeMode.system);
    theme.dispose();
  });

  test(
      'workspace ignores old bike mileage and returns cancellation after disposal',
      () async {
    final repository = FakeStravaBikesRepository();
    final strava = StravaController(repository, FakeStravaRepository());
    final workspace = WorkspaceController(
        bikeName: 'Old',
        bikeId: 'old',
        bikeType: BikeType.road,
        setupName: 'Default',
        setupId: 'setup',
        strava: strava);
    final old = workspace.loadMileage();
    final current =
        workspace.selectBike('New', 'new', BikeType.road, 'Default', 'setup');
    repository.mileage['new']!.complete(200);
    expect((await current).isSuccess, isTrue);
    repository.mileage['old']!.complete(100);
    expect((await old).isCancelled, isTrue);
    expect(workspace.mileageKm, 200);
    workspace.dispose();
    expect((await workspace.loadMileage()).isCancelled, isTrue);
    strava.dispose();
  });
}
