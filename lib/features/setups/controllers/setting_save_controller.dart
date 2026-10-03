import 'package:flutter/foundation.dart';

/// Serializes writes for one field. A failed write does not block retries.
class SettingWriteQueue {
  Future<void> _tail = Future<void>.value();
  Future<void> enqueue(Future<void> Function() write) {
    final result = _tail.then((_) => write());
    _tail = result.then((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }
}

/// Owns save revisions and retry state independently of editor focus/animation.
class SettingSaveController extends ChangeNotifier {
  SettingSaveController({SettingWriteQueue? writes})
      : _writes = writes ?? SettingWriteQueue();
  final SettingWriteQueue _writes;
  int _revision = 0;
  bool _disposed = false;
  bool saving = false;
  bool failed = false;
  bool dirty = false;

  Future<void> save(String value, Future<void> Function(String) write) async {
    dirty = false;
    final revision = ++_revision;
    saving = true;
    failed = false;
    notifyListeners();
    try {
      await _writes.enqueue(() => write(value));
      if (!_disposed && revision == _revision) {
        saving = false;
        notifyListeners();
      }
    } catch (_) {
      if (!_disposed && revision == _revision) {
        saving = false;
        failed = true;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
