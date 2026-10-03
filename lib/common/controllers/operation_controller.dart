import 'package:flutter/foundation.dart';

/// Tracks asynchronous commands while preserving their errors for the caller.
abstract class OperationController extends ChangeNotifier {
  int _pending = 0;
  Object? error;
  bool _disposed = false;
  bool get isBusy => _pending > 0;
  bool get isDisposed => _disposed;
  void emit() => _notify();

  Future<T> run<T>(Future<T> Function() action) async {
    _pending++;
    error = null;
    _notify();
    try {
      return await action();
    } catch (failure) {
      error = failure;
      rethrow;
    } finally {
      _pending--;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
