import '../models/strava_auth.dart';
import '../models/strava_bike.dart';

abstract interface class StravaRepository {
  Future<StravaAuth?> getAuth();
  Future<StravaAuth?> authorize();
  Future<void> authorizeWeb();
  Future<void> deauthorize();
  Future<String?> getValidToken();
  Future<List<StravaBike>> fetchAthleteBikes(String token);
  Future<double?> fetchMileageAtDate(
      {required String accessToken,
      required String gearId,
      required DateTime date,
      required double currentTotalKm});
  Future<DateTime?> getLastSyncTime();
  Future<void> markSynced();
}
