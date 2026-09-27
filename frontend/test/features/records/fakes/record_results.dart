import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// The value of [result], failing the test with the failure's message when
/// it is a [FailureResult].
T okOf<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      '${failure.runtimeType}: ${failure.message}',
    ),
  };
}

/// The failure [result] carries, failing the test when it is a [Success].
Failure failureOf<T>(Result<T> result) {
  return switch (result) {
    FailureResult<T>(:final Failure failure) => failure,
    Success<T>() => throw TestFailure('Expected a failure, got a success.'),
  };
}
