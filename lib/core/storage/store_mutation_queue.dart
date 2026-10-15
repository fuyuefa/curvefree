/// Runs store mutations one at a time.
///
/// File reads yield to the event loop, so two unqueued read-modify-write
/// calls can each snapshot the old document and the later write drops the
/// earlier one. Chaining each action onto the previous future closes that gap.
final class StoreMutationQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final Future<T> result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
