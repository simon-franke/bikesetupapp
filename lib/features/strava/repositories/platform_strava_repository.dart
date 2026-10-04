import 'package:shared_preferences/shared_preferences.dart';
import '../models/strava_auth.dart';
import '../models/strava_bike.dart';
import 'strava_repository.dart';
import 'strava_auth_service.dart';
import 'strava_api_service.dart';

class PlatformStravaRepository implements StravaRepository {
  PlatformStravaRepository(
      {required String? Function() userId,
      StravaAuthService? auth,
      StravaApiService? api})
      : _userId = userId,
        _auth = auth ?? StravaAuthService(userId: userId),
        _api = api ?? StravaApiService();
  final String? Function() _userId;
  final StravaAuthService _auth;
  final StravaApiService _api;
  static const _lastSyncKey = 'strava_last_sync';
  @override
  Future<StravaAuth?> getAuth() => _auth.getAuth();
  @override
  Future<StravaAuth?> authorize() => _auth.authorize();
  @override
  Future<void> authorizeWeb() => _auth.authorizeWeb();
  @override
  Future<void> clearAuth() async {
    final owner = _userId();
    await _auth.clearAuth();
    if (owner != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("${_lastSyncKey}_$owner");
    }
  }

  @override
  Future<void> deauthorize() => _auth.deauthorize();
  @override
  Future<String?> getValidToken() => _auth.getValidToken();
  @override
  Future<List<StravaBike>> fetchAthleteBikes(String token) =>
      _api.fetchAthleteBikes(token);
  @override
  Future<double?> fetchMileageAtDate(
      {required String gearId,
      required DateTime date,
      required double currentTotalKm}) async {
    final token = await _auth.getMileageToken();
    if (token == null) return null;
    return _api.fetchMileageAtDate(
        accessToken: token,
        gearId: gearId,
        date: date,
        currentTotalKm: currentTotalKm);
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final owner = _userId();
    if (owner == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt("${_lastSyncKey}_$owner");
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  @override
  Future<void> markSynced() async {
    final owner = _userId();
    if (owner == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${_lastSyncKey}_$owner",
        DateTime.now().toUtc().millisecondsSinceEpoch);
  }
}
