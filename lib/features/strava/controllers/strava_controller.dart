import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
import '../repositories/strava_bikes_repository.dart';
import '../repositories/strava_repository.dart';
import 'strava_sync_service.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';

class StravaController extends OperationController {
  StravaController(this._repository, StravaRepository connection) {
    _sync = StravaSyncService(_repository, connection, writes: _writes);
  }
  final WriteQueue _writes = WriteQueue();
  late final StravaSyncService _sync;
  Future<CommandResult<void>> sync() => share(
      'sync',
      () => command(() async {
            final generation = beginRequest('sync');
            final result = await _sync.sync(
                isCurrent: () => isCurrentRequest('sync', generation));
            result.requireValue();
          }));
  final StravaBikesRepository _repository;
  Stream<List<StravaBike>> getStravaBikes() => _repository.getStravaBikes();
  Future<CommandResult<void>> linkStravaBike(
          String stravaGearId, String appBikeId) =>
      command(() => _repository.linkStravaBike(stravaGearId, appBikeId));
  Future<CommandResult<void>> unlinkStravaBike(String stravaGearId) =>
      command(() => _repository.unlinkStravaBike(stravaGearId));
  Future<String?> getStravaGearIdForBike(String appBikeId) =>
      _repository.getStravaGearIdForBike(appBikeId);
  Future<double?> getMileageForBike(String appBikeId) =>
      _repository.getMileageForBike(appBikeId);
  Future<CommandResult<void>> deleteAllStravaBikes() => share(
      'deleteAll',
      () => command(() async {
            beginRequest('sync');
            await _writes.enqueue(_repository.deleteAllStravaBikes);
          }));
}
