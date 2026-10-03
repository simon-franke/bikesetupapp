import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
import '../repositories/strava_bikes_repository.dart';
import '../repositories/strava_repository.dart';
import 'strava_sync_service.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';

class StravaController extends OperationController {
  StravaController(this._repository, StravaRepository connection)
      : _sync = StravaSyncService(_repository, connection);
  final StravaSyncService _sync;
  String? get lastError => _sync.lastError;
  Future<bool>? _syncing;
  Future<bool> sync() =>
      _syncing ??= run(_sync.sync).whenComplete(() => _syncing = null);
  final StravaBikesRepository _repository;
  Future<void> saveStravaBikes(List<StravaBike> bikes) =>
      run(() => _repository.saveStravaBikes(bikes));
  Stream<List<StravaBike>> getStravaBikes() => _repository.getStravaBikes();
  Future<void> linkStravaBike(String stravaGearId, String appBikeId) =>
      run(() => _repository.linkStravaBike(stravaGearId, appBikeId));
  Future<void> unlinkStravaBike(String stravaGearId) =>
      run(() => _repository.unlinkStravaBike(stravaGearId));
  Future<String?> getStravaGearIdForBike(String appBikeId) =>
      _repository.getStravaGearIdForBike(appBikeId);
  Future<double?> getMileageForBike(String appBikeId) =>
      _repository.getMileageForBike(appBikeId);
  Future<void> deleteAllStravaBikes() =>
      run(() => _repository.deleteAllStravaBikes());
}
