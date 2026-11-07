/// Orders persistence operations while allowing a retry after a failed write.
class WriteQueue {
  Future<void> _tail = Future<void>.value();
  Future<T> enqueue<T>(Future<T> Function() write) {
    final result = _tail.then((_) => write());
    _tail =
        result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }
}
