import '../repositories/strava_repository.dart';
import '../repositories/strava_bikes_repository.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:bikesetupapp/features/strava/models/strava_exception.dart';

class StravaSyncService {
  final StravaBikesRepository _db;
  final StravaRepository _connection;

  StravaSyncService(this._db, this._connection);

  String? lastError;

  Future<bool> sync() async {
    lastError = null;
    try {
      final token = await _connection.getValidToken();
      if (token == null) {
        lastError =
            'Strava connection could not be renewed. Reconnect Strava in Settings.';
        return false;
      }

      final bikes = await _connection.fetchAthleteBikes(token);
      if (bikes.isEmpty) {
        lastError =
            'No bikes found in Strava. Add a bike under My Gear in Strava.';
        return false;
      }

      await _db.saveStravaBikes(bikes);

      await _connection.markSynced();

      return true;
    } on StravaApiException catch (e) {
      lastError = e.message;
      debugPrint('Strava sync error: $e');
      return false;
    } catch (e) {
      lastError =
          'Could not complete Strava sync. Check your connection and try again.';
      debugPrint('Strava sync error: $e');
      return false;
    }
  }
}
