import '../models/strava_bike.dart';

abstract interface class StravaBikesRepository {
  Future<void> saveStravaBikes(List<StravaBike> bikes);
  Stream<List<StravaBike>> getStravaBikes();
  Future<void> linkStravaBike(String stravaGearId, String appBikeId);
  Future<void> unlinkStravaBike(String stravaGearId);
  Future<String?> getStravaGearIdForBike(String appBikeId);
  Future<double?> getMileageForBike(String appBikeId);
  Future<void> deleteAllStravaBikes();
}
