import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Matches a [Success].
Matcher isSuccess<T>() => isA<Success<T>>();

/// Matches a [FailureResult] whose failure is [type].
Matcher isFailure<T, F extends Failure>() => isA<FailureResult<T>>().having(
  (FailureResult<T> result) => result.failure,
  'failure',
  isA<F>(),
);

/// The value of a [Success], or a [TestFailure] naming the failure.
T valueOf<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
