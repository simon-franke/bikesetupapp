import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bikesetupapp/database_service/strava_auth_service.dart';
import 'package:bikesetupapp/database_service/strava_api_service.dart';
import 'package:bikesetupapp/database_service/service_database.dart';

class StravaSyncService {
  final ServiceDatabaseService _db;
  final StravaAuthService _authService = StravaAuthService();
  final StravaApiService _apiService = StravaApiService();

  StravaSyncService(this._db);

  static const _lastSyncKey = 'strava_last_sync';

  String? lastError;

  Future<bool> sync() async {
    lastError = null;
    try {
      final token = await _authService.getValidToken();
      if (token == null) {
        lastError =
            'Strava connection could not be renewed. Reconnect Strava in Settings.';
        return false;
      }

      final bikes = await _apiService.fetchAthleteBikes(token);
      if (bikes.isEmpty) {
        lastError =
            'No bikes found in Strava. Add a bike under My Gear in Strava.';
        return false;
      }

      await _db.saveStravaBikes(bikes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastSyncKey, DateTime.now().toUtc().millisecondsSinceEpoch);

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

  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
}
