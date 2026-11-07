/// Orders persistence operations while allowing a retry after a failed write.
class WriteQueue {
  Future<void> _tail = Future<void>.value();

  /// Runs [write] after previously accepted writes have settled.
  ///
  /// Returns this write's result or error. Failure does not block later writes,
  /// and queued work is not cancelled when its caller stops awaiting it.
  Future<T> enqueue<T>(Future<T> Function() write) {
    final result = _tail.then((_) => write());
    _tail =
        result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }
}
