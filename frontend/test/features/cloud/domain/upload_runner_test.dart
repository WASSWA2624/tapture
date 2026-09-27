import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/cloud/domain/upload_runner.dart';

void main() {
  const Destination destination = (
    id: 'dest',
    kind: DestinationKind.s3,
    label: 'Archive',
    folder: 'inbox',
    credentialRef: 'ref',
    lastCheck: null,
  );

  test(
    'backoff resumes from the offset and the row starts interrupted',
    () async {
      final _MemoryHistory history = _MemoryHistory();
      final List<Duration> waits = <Duration>[];
      final _Flaky flaky = _Flaky(history);
      final UploadRunner runner = UploadRunner(
        destinationFor: (_) => flaky,
        history: history.port,
        clock: FixedClock(DateTime.utc(2026, 9, 28, 8)),
        wait: (Duration delay) async {
          waits.add(delay);
        },
      );
      final List<UploadProgress> progress = await runner
          .start(
            to: destination,
            file: (length: 20, read: (int _, int _) async => const <int>[]),
            filePath: 'pack.zip',
            remoteName: 'pack.zip',
            confirmed: true,
          )
          .toList();
      expect(history.rows.first.outcome, isNot('interrupted'));
      expect(flaky.sawInterrupted, isTrue);
      expect(flaky.offsets, <int>[0, 8]);
      expect(waits, <Duration>[
        Duration(milliseconds: AppConstants.cloudUpload.backoffBaseMs),
      ]);
      expect(progress.last.outcome, 'succeeded');
      expect(history.rows, hasLength(1));
    },
  );

  test('cancel and an unconfirmed start send nothing', () async {
    final _MemoryHistory history = _MemoryHistory();
    final _Gate gate = _Gate();
    final UploadRunner runner = UploadRunner(
      destinationFor: (_) => gate,
      history: history.port,
      clock: FixedClock(DateTime.utc(2026, 9, 28, 8)),
      wait: (_) async {},
    );
    final List<UploadProgress> refused = await runner
        .start(
          to: destination,
          file: (length: 4, read: (int _, int _) async => const <int>[]),
          filePath: 'pack.zip',
          remoteName: 'pack.zip',
          confirmed: false,
        )
        .toList();
    expect(refused.single.outcome, 'cancelled');
    expect(gate.calls, 0);
    expect(history.rows, isEmpty);

    final List<UploadProgress> cancelled = await runner
        .start(
          to: destination,
          file: (length: 4, read: (int _, int _) async => const <int>[]),
          filePath: 'pack.zip',
          remoteName: 'pack.zip',
          confirmed: true,
        )
        .toList();
    expect(cancelled.last.outcome, 'cancelled');
    expect(history.rows.single.outcome, 'cancelled');
  });

  test('retry writes a new attempt and still requires confirmation', () async {
    final _MemoryHistory history = _MemoryHistory();
    final _Flaky flaky = _Flaky(history)..succeedImmediately = true;
    final UploadRunner runner = UploadRunner(
      destinationFor: (_) => flaky,
      history: history.port,
      clock: FixedClock(DateTime.utc(2026, 9, 28, 8)),
      wait: (_) async {},
    );
    await runner
        .start(
          to: destination,
          file: (length: 4, read: (int _, int _) async => const <int>[]),
          filePath: 'pack.zip',
          remoteName: 'pack.zip',
          confirmed: true,
        )
        .drain<void>();
    expect(
      await runner.retry(
        attemptId: history.rows.single.id,
        confirmed: false,
        file: (length: 4, read: (int _, int _) async => const <int>[]),
        to: destination,
      ),
      isA<FailureResult<void>>(),
    );
    expect(history.rows, hasLength(1));
    expect(
      await runner.retry(
        attemptId: history.rows.single.id,
        confirmed: true,
        file: (length: 4, read: (int _, int _) async => const <int>[]),
        to: destination,
      ),
      isA<Success<void>>(),
    );
    expect(history.rows, hasLength(2));
    expect(history.rows.first.id, isNot(history.rows.last.id));
  });
}

final class _MemoryHistory {
  final List<UploadAttempt> rows = <UploadAttempt>[];

  UploadHistory get port => (
    begin: (UploadAttempt attempt) async {
      final UploadAttempt stored = (
        id: 'attempt-${rows.length + 1}',
        destinationId: attempt.destinationId,
        destinationLabel: attempt.destinationLabel,
        filePath: attempt.filePath,
        remoteName: attempt.remoteName,
        folder: attempt.folder,
        byteSize: attempt.byteSize,
        startedAt: attempt.startedAt,
        endedAt: null,
        outcome: 'interrupted',
        failureReason: null,
        offset: 0,
      );
      rows.add(stored);
      return Success<UploadAttempt>(stored);
    },
    finish: (UploadAttempt attempt) async {
      final int index = rows.indexWhere(
        (UploadAttempt row) => row.id == attempt.id,
      );
      rows[index] = attempt;
      return const Success<void>(null);
    },
    read: (String id) async {
      for (final UploadAttempt row in rows) {
        if (row.id == id) {
          return Success<UploadAttempt?>(row);
        }
      }
      return const Success<UploadAttempt?>(null);
    },
  );
}

final class _Flaky implements CloudDestination {
  _Flaky(this.history);

  final _MemoryHistory history;
  final List<int> offsets = <int>[];
  bool sawInterrupted = false;
  bool succeedImmediately = false;

  @override
  DestinationKind get kind => DestinationKind.s3;

  @override
  Future<Result<void>> check(Destination destination) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<Uri>> send(
    Destination destination,
    CloudBytes file, {
    required String remoteName,
    int offset = 0,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  }) async {
    sawInterrupted = history.rows.any(
      (UploadAttempt row) => row.outcome == 'interrupted',
    );
    offsets.add(offset);
    if (!succeedImmediately && offsets.length == 1) {
      onProgress?.call(8, file.length);
      return const FailureResult<Uri>(
        NetworkFailure(
          message: 'The destination did not finish the upload.',
          recoveryAction: 'Try again.',
        ),
      );
    }
    onProgress?.call(file.length, file.length);
    return Success<Uri>(Uri.parse('https://example.test/$remoteName'));
  }
}

final class _Gate implements CloudDestination {
  int calls = 0;

  @override
  DestinationKind get kind => DestinationKind.s3;

  @override
  Future<Result<void>> check(Destination destination) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<Uri>> send(
    Destination destination,
    CloudBytes file, {
    required String remoteName,
    int offset = 0,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  }) async {
    calls += 1;
    if (cancel != null) {
      cancel.cancel();
    }
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<Uri>(CancelledFailure());
    }
    return Success<Uri>(Uri.parse('https://example.test/$remoteName'));
  }
}
