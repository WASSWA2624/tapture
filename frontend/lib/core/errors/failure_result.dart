part of 'result.dart';

/// A completed call that produced [failure].
final class FailureResult<T> extends Result<T> {
  /// Creates a failed result.
  const FailureResult(this.failure);

  /// Why the call did not produce a value.
  final Failure failure;

  @override
  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess) {
    return onFailure(failure);
  }
}
