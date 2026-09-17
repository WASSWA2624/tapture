part of 'result.dart';

/// A completed call that produced [value].
final class Success<T> extends Result<T> {
  /// Creates a successful result.
  const Success(this.value);

  /// The value the call produced.
  final T value;

  @override
  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess) {
    return onSuccess(value);
  }
}
