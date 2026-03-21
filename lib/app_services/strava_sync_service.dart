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

  Future<bool> sync() async {
    try {
      final token = await _authService.getValidToken();
      if (token == null) return false;

      final bikes = await _apiService.fetchAthleteBikes(token);
      if (bikes.isEmpty) return false;

      await _db.saveStravaBikes(bikes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastSyncKey, DateTime.now().toUtc().millisecondsSinceEpoch);

      return true;
    } catch (e) {
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
