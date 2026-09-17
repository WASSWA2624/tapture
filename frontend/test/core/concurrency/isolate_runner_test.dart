import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

int increment(int value) => value + 1;

int boom(int _) => throw StateError('boom');

int halfThenDone(int value) {
  IsolateRunner.reportProgress(0.5);
  return value;
}

Future<int> sleepLong(int _) async {
  await Future<void>.delayed(const Duration(seconds: 30));
  return 0;
}

void main() {
  test('a successful task returns the value and leaves no isolate', () async {
    final Result<int> result = await runIsolate(increment, 1);

    expect(result.fold((_) => -1, (int value) => value), 2);
    expect(debugLiveIsolates, 0);
  });

  test('progress is forwarded from the worker', () async {
    final List<double> seen = <double>[];

    final Result<int> result = await runIsolate(
      halfThenDone,
      4,
      onProgress: seen.add,
    );

    expect(result.fold((_) => -1, (int value) => value), 4);
    expect(seen, contains(0.0));
    expect(seen, contains(0.5));
  });

  test('a thrown error becomes a Failure', () async {
    final Result<int> result = await runIsolate(boom, 0);

    expect(
      result.fold((Failure failure) => failure, (_) => null),
      isA<ProviderFailure>(),
    );
    expect(debugLiveIsolates, 0);
  });

  test('cancelling mid-run returns CancelledFailure and no orphan', () async {
    final CancellationToken cancel = CancellationToken();
    final Future<Result<int>> pending = runIsolate(
      sleepLong,
      0,
      cancel: cancel,
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(debugLiveIsolates, 1);
    cancel.cancel();

    final Result<int> result = await pending;
    expect(
      result.fold((Failure failure) => failure, (_) => null),
      isA<CancelledFailure>(),
    );
    expect(debugLiveIsolates, 0);
  });

  test('a token already cancelled does not spawn', () async {
    final CancellationToken cancel = CancellationToken()..cancel();

    final Result<int> result = await runIsolate(increment, 1, cancel: cancel);

    expect(
      result.fold((Failure failure) => failure, (_) => null),
      isA<CancelledFailure>(),
    );
    expect(debugLiveIsolates, 0);
  });
}
