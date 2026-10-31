import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import '../models/ride.dart';
import '../repositories/rides_repository.dart';

class RidesController extends OperationController {
  RidesController(this._repository);
  final RidesRepository _repository;
  final _writes = WriteQueue();
  Stream<List<Ride>> watch(String bikeId) => _repository.watch(bikeId);
  Future<CommandResult<int>> save(List<Ride> rides) =>
      command(() => _writes.enqueue(() async {
            if (isDisposed) throw const CommandAborted();
            if (rides.isEmpty ||
                rides.length > 100 ||
                rides.any((r) =>
                    r.bikeId.isEmpty ||
                    r.id.isEmpty ||
                    r.durationSeconds < 0 ||
                    (r.durationSeconds == 0 && (r.distanceKm ?? 0) <= 0) ||
                    (r.distanceKm != null &&
                        (!r.distanceKm!.isFinite || r.distanceKm! <= 0)) ||
                    r.durationSeconds > 7 * 24 * 3600 ||
                    r.startedAt.isAfter(DateTime.now().toUtc()))) {
              throw const AppFailure(FailureCode.invalidInput);
            }
            return _repository.insert(rides);
          }));
  Future<CommandResult<void>> remove(String id) =>
      command(() => _writes.enqueue(() {
            if (isDisposed) throw const CommandAborted();
            return _repository.remove(id);
          }));
}
