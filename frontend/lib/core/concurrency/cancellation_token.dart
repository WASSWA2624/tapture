import 'dart:async';

/// A one-shot signal that stops an isolate job.
final class CancellationToken {
  bool _cancelled = false;
  final List<void Function()> _waiters = <void Function()>[];

  /// Whether [cancel] has already been called.
  bool get isCancelled => _cancelled;

  /// Registered callbacks still retained by this token, for lifetime checks.
  int get debugListenerCount => _waiters.length;

  /// Waits until cancellation. Use [race] for work that can finish first.
  Future<void> get whenCancelled {
    if (_cancelled) return Future<void>.value();
    final Completer<void> completer = Completer<void>();
    _waiters.add(completer.complete);
    return completer.future;
  }

  /// Waits for [work] or cancellation, detaching when either completes.
  ///
  /// [onCancel] returns the cancelled result or throws a typed failure.
  /// The caller still owns stopping or closing the underlying operation.
  Future<T> race<T>(Future<T> work, {required T Function() onCancel}) async {
    final Completer<T> cancelled = Completer<T>();
    final void Function() detach = register(() {
      try {
        cancelled.complete(onCancel());
      } on Object catch (error, stack) {
        cancelled.completeError(error, stack);
      }
    });
    try {
      return await Future.any<T>(<Future<T>>[work, cancelled.future]);
    } finally {
      detach();
    }
  }

  /// Calls [listener] on cancellation and returns a way to detach it.
  void Function() register(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _waiters.add(listener);
    return () => _waiters.remove(listener);
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
