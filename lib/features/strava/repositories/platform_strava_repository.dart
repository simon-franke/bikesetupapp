import 'package:shared_preferences/shared_preferences.dart';
import '../models/strava_auth.dart';
import '../models/strava_bike.dart';
import 'strava_repository.dart';
import 'strava_auth_service.dart';
import 'strava_api_service.dart';
import 'strava_token_storage.dart';

class PlatformStravaRepository implements StravaRepository {
  PlatformStravaRepository({StravaAuthService? auth, StravaApiService? api})
      : _auth = auth ?? StravaAuthService(),
        _api = api ?? StravaApiService();
  final StravaAuthService _auth;
  final StravaApiService _api;
  static const _lastSyncKey = 'strava_last_sync';
  @override
  Future<StravaAuth?> getAuth() => StravaTokenStorage.getAuth();
  @override
  Future<StravaAuth?> authorize() => _auth.authorize();
  @override
  Future<void> authorizeWeb() => _auth.authorizeWeb();
  @override
  Future<void> deauthorize() => _auth.deauthorize();
  @override
  Future<String?> getValidToken() => _auth.getValidToken();
  @override
  Future<List<StravaBike>> fetchAthleteBikes(String token) =>
      _api.fetchAthleteBikes(token);
  @override
  Future<double?> fetchMileageAtDate(
          {required String accessToken,
          required String gearId,
          required DateTime date,
          required double currentTotalKm}) =>
      _api.fetchMileageAtDate(
          accessToken: accessToken,
          gearId: gearId,
          date: date,
          currentTotalKm: currentTotalKm);
  @override
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncKey);
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  @override
  Future<void> markSynced() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastSyncKey, DateTime.now().toUtc().millisecondsSinceEpoch);
  }
}
