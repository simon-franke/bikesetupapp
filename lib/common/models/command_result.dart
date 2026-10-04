enum FailureCode {
  permissionDenied,
  unavailable,
  saveFailed,
  loadFailed,
  authenticationFailed,
  invalidCredentials,
  emailInUse,
  weakPassword,
  invalidInput,
  connectionExpired,
  noStravaBikes,
  missingProfileScope,
  insufficientActivityScope,
  stravaInactive,
  stravaDenied,
  rateLimited,
  network,
  invalidResponse,
  stravaError,
}

/// Expected failure information without presentation text or persistence types.
class AppFailure implements Exception {
  const AppFailure(this.code, {this.cause, this.stackTrace, this.statusCode});
  final FailureCode code;
  final Object? cause;
  final StackTrace? stackTrace;
  final int? statusCode;
  @override
  String toString() => 'AppFailure(${code.name})';
}

/// Cancellation is distinct from a successful operation and from a failure.
class CommandAborted implements Exception {
  const CommandAborted();
}

sealed class CommandResult<T> {
  const CommandResult();
  bool get isSuccess => this is CommandSuccess<T>;
  bool get isCancelled => this is CommandCancelled<T>;
  AppFailure? get failure => switch (this) {
        CommandFailure<T>(:final reason) => reason,
        _ => null,
      };
  T requireValue() => switch (this) {
        CommandSuccess<T>(:final value) => value,
        CommandFailure<T>(:final reason) => throw reason,
        CommandCancelled<T>() => throw const CommandAborted(),
      };
}

class CommandSuccess<T> extends CommandResult<T> {
  const CommandSuccess(this.value);
  final T value;
}

class CommandFailure<T> extends CommandResult<T> {
  const CommandFailure(this.reason);
  final AppFailure reason;
}

class CommandCancelled<T> extends CommandResult<T> {
  const CommandCancelled();
}

/// Bridge for value-returning widget callbacks that already handle exceptions.
extension CommandValue<T> on Future<CommandResult<T>> {
  Future<T> orThrow() async => (await this).requireValue();
}
