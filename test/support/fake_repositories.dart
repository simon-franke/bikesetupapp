import 'dart:async';

import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/bikes/repositories/bikes_repository.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/repositories/maintenance_repository.dart';
import 'package:bikesetupapp/features/strava/models/strava_auth.dart';
import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
import 'package:bikesetupapp/features/strava/repositories/strava_repository.dart';
import 'package:bikesetupapp/features/strava/repositories/strava_bikes_repository.dart';

// Unused methods fail explicitly, so a newly introduced dependency cannot pass silently.
class FakeBikesRepository implements BikesRepository {
  String defaultBike = '';
  List<Bike> bikes = [];
  @override
  Future<String> getDefaultBike() async => defaultBike;
  @override
  Future<void> setDefaultBike(String id) async {
    defaultBike = id;
  }

  @override
  Future<void> createBikeRecord(String id, String name, String type) async {
    bikes.add(Bike(id: id, name: name, bikeType: type));
  }

  @override
  Stream<List<Bike>> getBikes() => Stream.value(bikes);
  @override
  Future<String> getBikeNameFromID(String id) async =>
      bikes.firstWhere((bike) => bike.id == id).name;
  @override
  Future<String> getBikeType(String id) async =>
      bikes.firstWhere((bike) => bike.id == id).bikeType;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class FakeSetupsRepository implements SetupsRepository {
  final Map<String, String> settings = {};
  final Map<String, String> defaults = {};
  final Map<String, String> names = {};
  Future<void> Function(
          String key, String value, String bike, String category, String setup)?
      onWrite;
  @override
  Future<void> setSetting(String key, String value, String bike,
      String category, String setup) async {
    if (onWrite != null) await onWrite!(key, value, bike, category, setup);
    settings['$bike/$setup/$category/$key'] = value;
  }

  @override
  Future<void> createSetupList(String bike, String setup, String name,
      Map<String, dynamic> information) async {
    names[setup] = name;
  }

  @override
  Future<void> setDefaultSetup(String bike, String setup) async {
    defaults[bike] = setup;
  }

  @override
  Future<String> getDefaultSetup(String bike) async => defaults[bike] ?? '';
  @override
  Future<String> getSetupNameFromID(String bike, String setup) async =>
      names[setup] ?? '';
  @override
  Stream<Map<String, dynamic>> getSettings(
          String bike, String category, String setup) =>
      Stream.value({
        for (final entry in settings.entries)
          if (entry.key.startsWith('$bike/$setup/$category/'))
            entry.key.split('/').last: entry.value,
      });
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class FakeMaintenanceRepository implements MaintenanceRepository {
  final Map<String, StreamController<ServiceEntry?>> latest = {};
  @override
  Stream<ServiceEntry?> streamLatestEntryForComponent(String id) => latest
      .putIfAbsent(id, () => StreamController<ServiceEntry?>.broadcast())
      .stream;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
  Future<void> close() async {
    for (final stream in latest.values) {
      await stream.close();
    }
  }
}

class FakeStravaBikesRepository implements StravaBikesRepository {
  List<StravaBike> bikes = [];
  final Map<String, Completer<double?>> mileage = {};
  int saves = 0;
  @override
  Future<void> saveStravaBikes(List<StravaBike> incoming) async {
    bikes = incoming;
    saves++;
  }

  @override
  Stream<List<StravaBike>> getStravaBikes() => Stream.value(bikes);
  @override
  Future<double?> getMileageForBike(String id) =>
      mileage.putIfAbsent(id, Completer<double?>.new).future;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class FakeStravaRepository implements StravaRepository {
  @override
  Future<void> clearAuth() async {}
  String? token = 'token';
  Object? failure;
  int markedSynced = 0;
  List<StravaBike> bikes = [];
  @override
  Future<String?> getValidToken() async => token;
  @override
  Future<List<StravaBike>> fetchAthleteBikes(String token) async {
    if (failure != null) throw failure!;
    return bikes;
  }

  @override
  Future<void> markSynced() async {
    markedSynced++;
  }

  @override
  Future<StravaAuth?> getAuth() async => null;
  @override
  Future<DateTime?> getLastSyncTime() async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
