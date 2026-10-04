import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import '../repositories/strava_repository.dart';
import '../repositories/strava_bikes_repository.dart';

/// Stateless workflow; its caller owns loading and failure presentation.
class StravaSyncService {
  StravaSyncService(this._db, this._connection, {WriteQueue? writes})
      : _writes = writes ?? WriteQueue();
  final WriteQueue _writes;
  final StravaBikesRepository _db;
  final StravaRepository _connection;

  Future<CommandResult<void>> sync({bool Function()? isCurrent}) async {
    void checkCurrent() {
      if (isCurrent != null && !isCurrent()) throw const CommandAborted();
    }

    try {
      checkCurrent();
      final token = await _connection.getValidToken();
      checkCurrent();
      if (token == null) throw const AppFailure(FailureCode.connectionExpired);
      final bikes = await _connection.fetchAthleteBikes(token);
      checkCurrent();
      if (bikes.isEmpty) throw const AppFailure(FailureCode.noStravaBikes);
      await _writes.enqueue(() {
        checkCurrent();
        return _db.saveStravaBikes(bikes);
      });
      checkCurrent();
      await _connection.markSynced();
      checkCurrent();
      return const CommandSuccess(null);
    } on AppFailure catch (failure) {
      return CommandFailure(failure);
    } on CommandAborted {
      return const CommandCancelled();
    }
  }
}
