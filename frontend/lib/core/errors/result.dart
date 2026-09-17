import 'failure.dart';

part 'failure_result.dart';
part 'success.dart';

/// The value of a fallible call: [Success] or [FailureResult].
sealed class Result<T> {
  /// Creates a result.
  const Result();

  /// Routes this result to [onFailure] or [onSuccess].
  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess);

  /// Maps a successful value; a failure is unchanged.
  Result<R> map<R>(R Function(T) convert) {
    return fold(FailureResult<R>.new, (T value) => Success<R>(convert(value)));
  }

  /// Chains a successful value into another [Result].
  Result<R> flatMap<R>(Result<R> Function(T) convert) {
    return fold(FailureResult<R>.new, convert);
  }

  /// The successful value, or [orElse] when this is a failure.
  T getOrElse(T Function() orElse) {
    return fold((_) => orElse(), (T value) => value);
  }

  /// Runs [body] and converts a thrown object into a [FailureResult].
  static Result<T> capture<T>(T Function() body) {
    try {
      return Success<T>(body());
    } on Object catch (error) {
      return FailureResult<T>(Failure.from(error));
    }
  }

  /// Runs [body] and converts a thrown object into a [FailureResult].
  static Future<Result<T>> captureAsync<T>(Future<T> Function() body) async {
    try {
      return Success<T>(await body());
    } on Object catch (error) {
      return FailureResult<T>(Failure.from(error));
    }
  }
}
