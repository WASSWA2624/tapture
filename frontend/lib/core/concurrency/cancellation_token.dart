import 'dart:async';

/// A one-shot signal that stops an isolate job.
final class CancellationToken {
  bool _cancelled = false;
  final List<void Function()> _waiters = <void Function()>[];

  /// Whether [cancel] has already been called.
  bool get isCancelled => _cancelled;

  /// Completes the first time [cancel] is called, or immediately if it was.
  Future<void> get whenCancelled {
    if (_cancelled) {
      return Future<void>.value();
    }
    final Completer<void> completer = Completer<void>();
    _waiters.add(completer.complete);
    return completer.future;
  }

  /// Stops the job. Safe to call more than once.
  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    final List<void Function()> waiters = List<void Function()>.of(_waiters);
    _waiters.clear();
    for (final void Function() waiter in waiters) {
      waiter();
    }
  }
}
