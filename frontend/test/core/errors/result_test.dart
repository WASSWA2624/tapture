import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test('fold routes a success to the value and a failure to the failure', () {
    const Result<int> ok = Success<int>(2);
    const Result<int> bad = FailureResult<int>(ValidationFailure());

    expect(ok.fold((_) => -1, (int value) => value), 2);
    expect(
      bad.fold((Failure failure) => failure, (_) => null),
      isA<ValidationFailure>(),
    );
  });

  test('map transforms a success and leaves a failure unchanged', () {
    const Result<int> ok = Success<int>(2);
    const Result<int> bad = FailureResult<int>(StorageFailure());

    expect(
      ok.map((int value) => value * 3).fold((_) => 0, (int value) => value),
      6,
    );
    expect(
      bad.map((int value) => value * 3).fold((Failure f) => f, (_) => null),
      isA<StorageFailure>(),
    );
  });

  test('flatMap chains a success and leaves a failure unchanged', () {
    const Result<int> ok = Success<int>(2);
    const Result<int> bad = FailureResult<int>(NetworkFailure());

    expect(
      ok
          .flatMap((int value) => Success<String>('$value'))
          .fold((_) => '', (String value) => value),
      '2',
    );
    expect(
      ok
          .flatMap((_) => const FailureResult<String>(PermissionFailure()))
          .fold((Failure f) => f, (_) => null),
      isA<PermissionFailure>(),
    );
    expect(
      bad
          .flatMap((int value) => Success<String>('$value'))
          .fold((Failure f) => f, (_) => null),
      isA<NetworkFailure>(),
    );
  });

  test('getOrElse returns the value or the fallback', () {
    const Result<int> ok = Success<int>(2);
    const Result<int> bad = FailureResult<int>(CancelledFailure());

    expect(ok.getOrElse(() => 9), 2);
    expect(bad.getOrElse(() => 9), 9);
  });

  test('capture converts known exceptions into the matching Failure', () {
    expect(Result.capture(() => 4), isA<Success<int>>());
    expect(
      Result.capture(
        () => throw const FormatException(),
      ).fold((Failure f) => f, (_) => null),
      isA<CorruptionFailure>(),
    );
    expect(
      Result.capture(
        () => throw ArgumentError(),
      ).fold((Failure f) => f, (_) => null),
      isA<ValidationFailure>(),
    );
    expect(
      Result.capture(
        () => throw TimeoutException('late'),
      ).fold((Failure f) => f, (_) => null),
      isA<NetworkFailure>(),
    );
    expect(
      Result.capture(
        () => throw StateError('boom'),
      ).fold((Failure f) => f, (_) => null),
      isA<ProviderFailure>(),
    );
    expect(
      Result.capture(
        () => throw const StorageFailure(),
      ).fold((Failure f) => f, (_) => null),
      isA<StorageFailure>(),
    );
  });

  test('captureAsync converts a thrown object the same way', () async {
    final Result<int> ok = await Result.captureAsync(() async => 4);
    final Result<int> bad = await Result.captureAsync(
      () async => throw const FormatException(),
    );

    expect(ok.fold((_) => 0, (int value) => value), 4);
    expect(bad.fold((Failure f) => f, (_) => null), isA<CorruptionFailure>());
  });

  test('every Failure variant carries a message and a recovery action', () {
    const List<Failure> variants = <Failure>[
      StorageFailure(),
      PermissionFailure(),
      NetworkFailure(),
      ProviderFailure(),
      ValidationFailure(),
      CorruptionFailure(),
      CancelledFailure(),
    ];

    for (final Failure failure in variants) {
      expect(failure.message, isNotEmpty);
      expect(failure.recoveryAction, isNotEmpty);
      expect(failure.message, isNot(failure.toString()));
    }
  });
}
