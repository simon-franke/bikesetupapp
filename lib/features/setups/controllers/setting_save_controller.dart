import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/models/command_result.dart';

/// Serializes writes for one field. A failed write does not block retries.
class SettingWriteQueue extends WriteQueue {}

class SettingSaveController extends OperationController {
  SettingSaveController({SettingWriteQueue? writes})
      : _writes = writes ?? SettingWriteQueue();
  final SettingWriteQueue _writes;
  bool _saving = false;
  bool _failed = false;
  bool _dirty = false;
  bool get saving => _saving;
  bool get failed => _failed;
  bool get dirty => _dirty;
  void markDirty() {
    if (!isDisposed) {
      _dirty = true;
      emit();
    }
  }

  Future<CommandResult<void>> save(
          String value, Future<void> Function(String) write) =>
      command(() async {
        final generation = beginRequest('save');
        _dirty = false;
        _saving = true;
        _failed = false;
        emit();
        try {
          // Accepted edits must persist even if the user switches fields.
          await _writes.enqueue(() => write(value));
          if (!isCurrentRequest('save', generation)) {
            throw const CommandAborted();
          }
        } catch (error) {
          if (isCurrentRequest('save', generation) && error is! CommandAborted) {
            _failed = true;
          }
          rethrow;
        } finally {
          if (isCurrentRequest('save', generation)) {
            _saving = false;
            emit();
          }
        }
      });
}
