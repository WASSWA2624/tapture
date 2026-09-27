import 'dart:async';

import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/cloud_file_range.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

/// Moves one confirmed file to a destination, with retry, resume and history.
///
/// Nothing here starts by itself. [confirmed] must be true or no credential
/// is read and no request is made. A retry asks for confirmation again.
final class UploadRunner {
  /// Creates a runner. [history] records the attempt before the first byte.
  UploadRunner({
    required this.destinationFor,
    required this.history,
    required this.clock,
    Future<void> Function(Duration delay)? wait,
    int? maxAttempts,
  }) : _wait = wait ?? ((Duration delay) => Future<void>.delayed(delay)),
       _maxAttempts = maxAttempts ?? AppConstants.cloudUpload.maxAttempts;

  /// Resolves the backend for a destination kind.
  final CloudDestination Function(DestinationKind kind) destinationFor;

  /// Where attempt rows are written.
  final UploadHistory history;

  /// Clock for attempt timestamps.
  final Clock clock;
  final Future<void> Function(Duration delay) _wait;
  final int _maxAttempts;
  final Map<String, CancellationToken> _tokens = <String, CancellationToken>{};

  /// Bytes of [path], read one slice at a time off the UI isolate.
  CloudBytes openFile(String path, int length) => cloudFile(path, length);

  /// Sends [file] to [to]. Writes an interrupted history row first.
  Stream<UploadProgress> start({
    required Destination to,
    required CloudBytes file,
    required String filePath,
    required String remoteName,
    required bool confirmed,
  }) async* {
    if (!confirmed) {
      yield (
        attemptId: '',
        sent: 0,
        total: file.length,
        outcome: 'cancelled',
        failureReason: 'Confirm this upload before it can start.',
      );
      return;
    }
    final DateTime started = clock.nowUtc();
    final Result<UploadAttempt> begun = await history.begin((
      id: '',
      destinationId: to.id,
      destinationLabel: to.label,
      filePath: filePath,
      remoteName: remoteName,
      folder: to.folder,
      byteSize: file.length,
      startedAt: started,
      endedAt: null,
      outcome: 'interrupted',
      failureReason: null,
      offset: 0,
    ));
    if (begun is FailureResult<UploadAttempt>) {
      yield (
        attemptId: '',
        sent: 0,
        total: file.length,
        outcome: 'failed',
        failureReason: begun.failure.message,
      );
      return;
    }
    final UploadAttempt attempt = (begun as Success<UploadAttempt>).value;
    final CancellationToken token = CancellationToken();
    _tokens[attempt.id] = token;
    var acknowledged = 0;
    CloudDestination destination;
    try {
      destination = destinationFor(to.kind);
    } on Object {
      yield* _close(
        attempt,
        outcome: 'failed',
        sent: 0,
        failureReason:
            'No upload destination is registered for ${to.kind.name}.',
      );
      return;
    }
    for (var attemptNumber = 0; attemptNumber < _maxAttempts; attemptNumber++) {
      if (token.isCancelled) {
        yield* _close(attempt, outcome: 'cancelled', sent: acknowledged);
        return;
      }
      final Result<Uri> sent = await destination.send(
        to,
        file,
        remoteName: remoteName,
        offset: acknowledged,
        cancel: token,
        onProgress: (int done, int _) {
          acknowledged = done;
        },
      );
      if (sent is Success<Uri>) {
        yield* _close(attempt, outcome: 'succeeded', sent: file.length);
        return;
      }
      final Failure failure = (sent as FailureResult<Uri>).failure;
      if (failure is CancelledFailure || token.isCancelled) {
        yield* _close(attempt, outcome: 'cancelled', sent: acknowledged);
        return;
      }
      if (!cloudRetryable(failure) || attemptNumber + 1 >= _maxAttempts) {
        yield* _close(
          attempt,
          outcome: 'failed',
          sent: acknowledged,
          failureReason: failure.message,
        );
        return;
      }
      yield (
        attemptId: attempt.id,
        sent: acknowledged,
        total: file.length,
        outcome: 'interrupted',
        failureReason: failure.message,
      );
      await _wait(
        cloudBackoff(
          attemptNumber,
          baseMs: AppConstants.cloudUpload.backoffBaseMs,
          capMs: AppConstants.cloudUpload.backoffCapMs,
        ),
      );
    }
  }

  /// Stops [attemptId]. The local file and the destination row stay.
  Future<Result<void>> cancel(String attemptId) async {
    _tokens[attemptId]?.cancel();
    final Result<UploadAttempt?> existing = await history.read(attemptId);
    final UploadAttempt? row = existing.fold(
      (_) => null,
      (UploadAttempt? value) => value,
    );
    if (row == null) {
      return const Success<void>(null);
    }
    await history.finish((
      id: row.id,
      destinationId: row.destinationId,
      destinationLabel: row.destinationLabel,
      filePath: row.filePath,
      remoteName: row.remoteName,
      folder: row.folder,
      byteSize: row.byteSize,
      startedAt: row.startedAt,
      endedAt: clock.nowUtc(),
      outcome: 'cancelled',
      failureReason: const CancelledFailure().message,
      offset: row.offset,
    ));
    return const Success<void>(null);
  }

  /// Sends [attemptId] again. [confirmed] must be true, and a new row is written.
  Future<Result<void>> retry({
    required String attemptId,
    required bool confirmed,
    required CloudBytes file,
    required Destination to,
  }) async {
    if (!confirmed) {
      return const FailureResult<void>(
        CancelledFailure(
          message: 'Confirm this upload before it can start.',
          recoveryAction: 'Review the file and confirm it.',
        ),
      );
    }
    final Result<UploadAttempt?> existing = await history.read(attemptId);
    if (existing is FailureResult<UploadAttempt?>) {
      return FailureResult<void>(existing.failure);
    }
    final UploadAttempt? previous = (existing as Success<UploadAttempt?>).value;
    if (previous == null) {
      return const FailureResult<void>(
        ValidationFailure(
          message: 'That upload is no longer in the history.',
          recoveryAction: 'Start the upload again.',
        ),
      );
    }
    await start(
      to: to,
      file: file,
      filePath: previous.filePath,
      remoteName: previous.remoteName,
      confirmed: true,
    ).drain<void>();
    return const Success<void>(null);
  }

  Stream<UploadProgress> _close(
    UploadAttempt attempt, {
    required String outcome,
    required int sent,
    String? failureReason,
  }) async* {
    final UploadAttempt closed = (
      id: attempt.id,
      destinationId: attempt.destinationId,
      destinationLabel: attempt.destinationLabel,
      filePath: attempt.filePath,
      remoteName: attempt.remoteName,
      folder: attempt.folder,
      byteSize: attempt.byteSize,
      startedAt: attempt.startedAt,
      endedAt: clock.nowUtc(),
      outcome: outcome,
      failureReason: failureReason,
      offset: sent,
    );
    await history.finish(closed);
    _tokens.remove(attempt.id);
    yield (
      attemptId: attempt.id,
      sent: sent,
      total: attempt.byteSize,
      outcome: outcome,
      failureReason: failureReason,
    );
  }
}

/// One upload attempt. [outcome] is interrupted until the transfer ends.
typedef UploadAttempt = ({
  String id,
  String destinationId,
  String destinationLabel,
  String filePath,
  String remoteName,
  String folder,
  int byteSize,
  DateTime startedAt,
  DateTime? endedAt,
  String outcome,
  String? failureReason,
  int offset,
});

/// Progress the interface can show while a transfer runs.
typedef UploadProgress = ({
  String attemptId,
  int sent,
  int total,
  String outcome,
  String? failureReason,
});

/// History the runner writes. The row exists before the first request.
typedef UploadHistory = ({
  Future<Result<UploadAttempt>> Function(UploadAttempt attempt) begin,
  Future<Result<void>> Function(UploadAttempt attempt) finish,
  Future<Result<UploadAttempt?>> Function(String id) read,
});
