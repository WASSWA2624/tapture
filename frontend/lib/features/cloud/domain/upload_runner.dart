import 'dart:async';

import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/cloud_file_range.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/domain_copy.g.dart';
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
    this.wait,
    int? maxAttempts,
    this._beforeSend,
  }) : _maxAttempts = maxAttempts ?? AppConstants.cloudUpload.maxAttempts;

  /// Resolves the backend for a destination kind, or names why none is
  /// registered (see [resolveDestination]).
  final Result<CloudDestination> Function(DestinationKind kind) destinationFor;

  /// Where attempt rows are written.
  final UploadHistory history;

  /// Clock for attempt timestamps.
  final Clock clock;

  /// Optional retry scheduler for deterministic tests; production owns a timer.
  final Future<void> Function(Duration delay)? wait;
  final int _maxAttempts;
  final Future<Result<void>> Function(String)? _beforeSend;
  final Map<String, CancellationToken> _tokens = <String, CancellationToken>{};

  /// Bytes of [path], read one slice at a time off the UI isolate.
  CloudBytes openFile(String path, int length) => cloudFile(path, length);

  /// Sends [file] to [to]. Writes an interrupted history row first, then
  /// reports each acknowledged byte count as `sending` until the attempt
  /// ends as `succeeded`, `failed` or `cancelled`.
  Stream<UploadProgress> start({
    required Destination to,
    required CloudBytes file,
    required String filePath,
    required String remoteName,
    required bool confirmed,
  }) {
    final StreamController<UploadProgress> events =
        StreamController<UploadProgress>();
    unawaited(
      _run(
        to: to,
        file: file,
        filePath: filePath,
        remoteName: remoteName,
        confirmed: confirmed,
        emit: events.add,
      ).whenComplete(events.close),
    );
    return events.stream;
  }

  Future<void> _run({
    required Destination to,
    required CloudBytes file,
    required String filePath,
    required String remoteName,
    required bool confirmed,
    required void Function(UploadProgress progress) emit,
  }) async {
    if (!confirmed) {
      emit((
        attemptId: '',
        sent: 0,
        total: file.length,
        outcome: 'cancelled',
        failureReason: 'Confirm this upload before it can start.',
        localizedFailure: DomainCopy.messages.uploadStopped,
      ));
      return;
    }
    final Result<void>? permitted = await _beforeSend?.call(filePath);
    if (permitted case FailureResult<void>(:final Failure failure)) {
      emit((
        attemptId: '',
        sent: 0,
        total: file.length,
        outcome: 'failed',
        failureReason: failure.message,
        localizedFailure: failure.explanation,
      ));
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
      localizedFailure: null,
      offset: 0,
    ));
    if (begun is FailureResult<UploadAttempt>) {
      emit((
        attemptId: '',
        sent: 0,
        total: file.length,
        outcome: 'failed',
        failureReason: begun.failure.message,
        localizedFailure: begun.failure.explanation,
      ));
      return;
    }
    final UploadAttempt attempt = (begun as Success<UploadAttempt>).value;
    final CancellationToken token = CancellationToken();
    _tokens[attempt.id] = token;
    emit((
      attemptId: attempt.id,
      sent: 0,
      total: file.length,
      outcome: 'sending',
      failureReason: null,
      localizedFailure: null,
    ));
    final Result<CloudDestination> resolved = destinationFor(to.kind);
    if (resolved is FailureResult<CloudDestination>) {
      emit(
        await _close(
          attempt,
          outcome: 'failed',
          sent: 0,
          failureReason: resolved.failure.message,
          localizedFailure: resolved.failure.explanation,
        ),
      );
      return;
    }
    final CloudDestination destination =
        (resolved as Success<CloudDestination>).value;
    var acknowledged = 0;
    int? pendingOffset;
    Future<void>? checkpointWrite;
    Failure? checkpointFailure;
    void checkpoint(int offset) {
      pendingOffset = offset;
      checkpointWrite ??= () async {
        while (pendingOffset != null && checkpointFailure == null) {
          final int next = pendingOffset!;
          pendingOffset = null;
          final Result<void> saved = await history.finish(
            _snapshot(attempt, offset: next),
          );
          if (saved case FailureResult<void>(:final Failure failure)) {
            checkpointFailure = failure;
            token.cancel();
          }
        }
        checkpointWrite = null;
      }();
    }

    for (var attemptNumber = 0; attemptNumber < _maxAttempts; attemptNumber++) {
      if (token.isCancelled) {
        emit(await _close(attempt, outcome: 'cancelled', sent: acknowledged));
        return;
      }
      final Result<void>? permitted = await _beforeSend?.call(filePath);
      if (permitted case FailureResult<void>(:final Failure failure)) {
        emit(
          await _close(
            attempt,
            outcome: 'failed',
            sent: acknowledged,
            failureReason: failure.message,
            localizedFailure: failure.explanation,
          ),
        );
        return;
      }
      final Result<Uri> sent = await Result.captureAsync<Uri>(
        () async => (await destination.send(
          to,
          file,
          remoteName: remoteName,
          offset: acknowledged,
          cancel: token,
          onProgress: (int done, int _) {
            acknowledged = done.clamp(0, file.length);
            checkpoint(acknowledged);
            emit((
              attemptId: attempt.id,
              sent: acknowledged,
              total: file.length,
              outcome: 'sending',
              failureReason: null,
              localizedFailure: null,
            ));
          },
        )).getOrThrow(),
      );
      await checkpointWrite;
      if (checkpointFailure case final Failure failure) {
        emit(
          await _close(
            attempt,
            outcome: 'failed',
            sent: acknowledged,
            failureReason: failure.message,
            localizedFailure: failure.explanation,
          ),
        );
        return;
      }
      if (sent is Success<Uri>) {
        emit(await _close(attempt, outcome: 'succeeded', sent: file.length));
        return;
      }
      final Failure failure = (sent as FailureResult<Uri>).failure;
      if (failure is CancelledFailure || token.isCancelled) {
        emit(await _close(attempt, outcome: 'cancelled', sent: acknowledged));
        return;
      }
      if (!cloudRetryable(failure) || attemptNumber + 1 >= _maxAttempts) {
        emit(
          await _close(
            attempt,
            outcome: 'failed',
            sent: acknowledged,
            failureReason: failure.message,
            localizedFailure: failure.explanation,
          ),
        );
        return;
      }
      emit((
        attemptId: attempt.id,
        sent: acknowledged,
        total: file.length,
        outcome: 'interrupted',
        failureReason: failure.message,
        localizedFailure: failure.explanation,
      ));
      await _pause(
        cloudBackoff(
          attemptNumber,
          baseMs: AppConstants.cloudUpload.backoffBaseMs,
          capMs: AppConstants.cloudUpload.backoffCapMs,
        ),
        token,
      );
    }
  }

  Future<void> _pause(Duration delay, CancellationToken token) async {
    final Completer<void> stopped = Completer<void>();
    final void Function() detach = token.register(stopped.complete);
    Timer? timer;
    try {
      final Future<void> Function(Duration)? scheduler = wait;
      final Future<void> elapsed;
      if (scheduler == null) {
        final Completer<void> ready = Completer<void>();
        timer = Timer(delay, ready.complete);
        elapsed = ready.future;
      } else {
        elapsed = scheduler(delay);
      }
      await Future.any<void>(<Future<void>>[elapsed, stopped.future]);
    } finally {
      timer?.cancel();
      detach();
    }
  }

  /// Stops [attemptId]. The local file and the destination row stay.
  Future<Result<void>> cancel(String attemptId) async {
    final CancellationToken? active = _tokens[attemptId];
    if (active != null) {
      active.cancel();
      // The running transfer drains ordered checkpoints before its final
      // cancelled row. A second writer here could be overwritten by them.
      return const Success<void>(null);
    }
    final Result<UploadAttempt?> existing = await history.read(attemptId);
    if (existing case FailureResult<UploadAttempt?>(:final Failure failure)) {
      return FailureResult<void>(failure);
    }
    final UploadAttempt? row = existing.fold(
      (_) => null,
      (UploadAttempt? value) => value,
    );
    if (row == null) {
      return const Success<void>(null);
    }
    if (row.outcome != 'interrupted' && row.outcome != 'sending') {
      return const Success<void>(null);
    }
    return history.finish((
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
      localizedFailure: DomainCopy.messages.uploadStopped,
      offset: row.offset,
    ));
  }

  /// Sends [attemptId] again. [confirmed] must be true, and a new row is
  /// written. Completes once the new attempt has ended; its outcome is in
  /// the history and was the last event given to [onProgress].
  Future<Result<void>> retry({
    required String attemptId,
    required bool confirmed,
    required CloudBytes file,
    required Destination to,
    void Function(UploadProgress progress)? onProgress,
  }) async {
    if (!confirmed) {
      return FailureResult<void>(
        CancelledFailure(
          message: 'Confirm this upload before it can start.',
          localizedMessage: DomainCopy.messages.cloudUploadConfirmationRequired,
          recoveryAction: 'Review the file and confirm it.',
          localizedRecovery:
              DomainCopy.messages.cloudUploadConfirmationRecovery,
        ),
      );
    }
    final Result<UploadAttempt?> existing = await history.read(attemptId);
    if (existing is FailureResult<UploadAttempt?>) {
      return FailureResult<void>(existing.failure);
    }
    final UploadAttempt? previous = (existing as Success<UploadAttempt?>).value;
    if (previous == null) {
      return FailureResult<void>(
        ValidationFailure(
          message: 'That upload is no longer in the history.',
          localizedMessage: DomainCopy.messages.cloudUploadHistoryMissing,
          recoveryAction: 'Start the upload again.',
          localizedRecovery: DomainCopy.messages.cloudUploadRestartRecovery,
        ),
      );
    }
    await for (final UploadProgress progress in start(
      to: to,
      file: file,
      filePath: previous.filePath,
      remoteName: previous.remoteName,
      confirmed: true,
    )) {
      onProgress?.call(progress);
    }
    return const Success<void>(null);
  }

  Future<UploadProgress> _close(
    UploadAttempt attempt, {
    required String outcome,
    required int sent,
    String? failureReason,
    LocalizedMessage? localizedFailure,
  }) async {
    final UploadAttempt closed = _snapshot(
      attempt,
      offset: sent,
      outcome: outcome,
      endedAt: clock.nowUtc(),
      failureReason: failureReason,
      localizedFailure: localizedFailure,
    );
    final Result<void> stored = await history.finish(closed);
    _tokens.remove(attempt.id);
    return (
      attemptId: attempt.id,
      sent: sent,
      total: attempt.byteSize,
      outcome: stored is FailureResult<void> ? 'failed' : outcome,
      failureReason: stored is FailureResult<void>
          ? stored.failure.message
          : failureReason,
      localizedFailure: stored is FailureResult<void>
          ? stored.failure.explanation
          : localizedFailure,
    );
  }

  UploadAttempt _snapshot(
    UploadAttempt attempt, {
    required int offset,
    String outcome = 'interrupted',
    DateTime? endedAt,
    String? failureReason,
    LocalizedMessage? localizedFailure,
  }) => (
    id: attempt.id,
    destinationId: attempt.destinationId,
    destinationLabel: attempt.destinationLabel,
    filePath: attempt.filePath,
    remoteName: attempt.remoteName,
    folder: attempt.folder,
    byteSize: attempt.byteSize,
    startedAt: attempt.startedAt,
    endedAt: endedAt,
    outcome: outcome,
    failureReason: failureReason,
    localizedFailure: localizedFailure,
    offset: offset,
  );
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
  LocalizedMessage? localizedFailure,
  int offset,
});

/// Progress the interface can show while a transfer runs. [outcome] is
/// `sending` while bytes move, `interrupted` while a retry waits, then
/// `succeeded`, `failed` or `cancelled`.
typedef UploadProgress = ({
  String attemptId,
  int sent,
  int total,
  String outcome,
  String? failureReason,
  LocalizedMessage? localizedFailure,
});

/// History the runner writes. The row exists before the first request.
typedef UploadHistory = ({
  Future<Result<UploadAttempt>> Function(UploadAttempt attempt) begin,
  Future<Result<void>> Function(UploadAttempt attempt) finish,
  Future<Result<UploadAttempt?>> Function(String id) read,
});
