import 'package:flutter/foundation.dart';
import '../models/command_result.dart';

/// Owns command activity, failures and request validity for one controller.
abstract class OperationController extends ChangeNotifier {
  int _pending = 0;
  int _operationRevision = 0;
  Object? _error;
  StackTrace? _errorStackTrace;
  bool _disposed = false;
  final Map<String, int> _requests = {};
  final Map<Object, Future<dynamic>> _shared = {};

  bool get isBusy => _pending > 0;
  Object? get error => _error;
  StackTrace? get errorStackTrace => _errorStackTrace;
  AppFailure? get failure => _error is AppFailure ? _error as AppFailure : null;
  bool get isDisposed => _disposed;

  @protected
  void emit() {
    if (!_disposed) notifyListeners();
  }

  @protected
  int beginRequest(String name) =>
      _requests.update(name, (value) => value + 1, ifAbsent: () => 1);
  @protected
  bool isCurrentRequest(String name, int generation) =>
      !_disposed && _requests[name] == generation;

  @protected
  Future<T> share<T>(Object name, Future<T> Function() action) {
    final existing = _shared[name];
    if (existing != null) return existing as Future<T>;
    final future = action().whenComplete(() {
      _shared.remove(name);
    });
    _shared[name] = future;
    return future;
  }

  @protected
  Future<T> run<T>(Future<T> Function() action) async {
    if (_disposed) throw const CommandAborted();
    final revision = ++_operationRevision;
    _pending++;
    _error = null;
    _errorStackTrace = null;
    emit();
    try {
      return await action();
    } catch (error, stack) {
      if (!_disposed &&
          revision == _operationRevision &&
          error is! CommandAborted) {
        _error = error;
        _errorStackTrace = stack;
      }
      rethrow;
    } finally {
      _pending--;
      emit();
    }
  }

  @protected
  Future<CommandResult<T>> command<T>(Future<T> Function() action) async {
    try {
      final value = await run(action);
      if (isDisposed) return const CommandCancelled();
      return CommandSuccess(value);
    } on AppFailure catch (failure) {
      if (isDisposed) return const CommandCancelled();
      return CommandFailure(failure);
    } on CommandAborted {
      return const CommandCancelled();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requests.clear();
    super.dispose();
  }
}
