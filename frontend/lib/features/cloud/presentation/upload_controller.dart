import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/cloud_file_range.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';

import '../cloud.dart'
    show
        DestinationRepositoryImpl,
        cloudBackendsProvider,
        cloudExportGuardProvider,
        cloudOperationPolicyProvider,
        destinationRepositoryProvider;
import '../domain/upload_runner.dart';

/// Runs the uploads a person confirmed, and knows which are still moving
/// (task 021 step 6).
///
/// It lives for the whole session, so a transfer keeps going when its page
/// closes. Nothing here starts on its own: [send] and [retry] refuse to move
/// a byte unless their caller passes the confirmation sheet's answer. The
/// state is each running attempt's latest progress, by attempt id.
final class UploadController extends Notifier<Map<String, UploadProgress>> {
  UploadRunner? _runner;

  @override
  Map<String, UploadProgress> build() => const <String, UploadProgress>{};

  /// Sends the file at [filePath] to [to] as [remoteName]. Completes with
  /// the attempt's last progress: its outcome and any failure reason.
  Future<UploadProgress> send({
    required Destination to,
    required String filePath,
    required String remoteName,
    required bool confirmed,
  }) async {
    if (confirmed) {
      final Result<void> permitted = ref
          .read(cloudOperationPolicyProvider)
          .check(to, upload: true);
      if (permitted case FailureResult<void>(:final failure)) {
        return _refused(failure.explanation);
      }
    }
    final int? length = await cloudFileLength(filePath);
    if (length == null) {
      return _refused(Copy.messages.uploadFileMissing);
    }
    final UploadRunner runner = await _open();
    UploadProgress? last;
    await for (final UploadProgress progress in runner.start(
      to: to,
      file: runner.openFile(filePath, length),
      filePath: filePath,
      remoteName: remoteName,
      confirmed: confirmed,
    )) {
      last = progress;
      _track(progress);
    }
    return last ?? _refused(Copy.messages.uploadFileMissing);
  }

  /// Sends a failed or interrupted [attempt] again to the same destination,
  /// as a new attempt row. The file must still be the one exported.
  Future<UploadProgress> retry(
    UploadAttempt attempt, {
    required bool confirmed,
  }) async {
    final DestinationRepositoryImpl store = ref.read(
      destinationRepositoryProvider,
    );
    Destination? to;
    for (final Destination row in await store.watchAll().first) {
      if (row.id == attempt.destinationId) {
        to = row;
      }
    }
    if (to == null) {
      return _refused(Copy.messages.uploadDestinationGone);
    }
    if (confirmed) {
      final Result<void> permitted = ref
          .read(cloudOperationPolicyProvider)
          .check(to, upload: true);
      if (permitted case FailureResult<void>(:final failure)) {
        return _refused(failure.explanation);
      }
    }
    final int? length = await cloudFileLength(attempt.filePath);
    if (length == null || length != attempt.byteSize) {
      return _refused(Copy.messages.uploadFileMissing);
    }
    final UploadRunner runner = await _open();
    UploadProgress? last;
    final Result<void> ran = await runner.retry(
      attemptId: attempt.id,
      confirmed: confirmed,
      file: runner.openFile(attempt.filePath, length),
      to: to,
      onProgress: (UploadProgress progress) {
        last = progress;
        _track(progress);
      },
    );
    return ran.fold(
      (failure) => _refused(failure.explanation),
      (_) => last ?? _refused(Copy.messages.uploadFileMissing),
    );
  }

  /// Stops [attemptId]. The file on this device and the destination stay.
  Future<void> cancel(String attemptId) async {
    await _runner?.cancel(attemptId);
  }

  Future<UploadRunner> _open() async {
    final UploadRunner? open = _runner;
    if (open != null) {
      return open;
    }
    final DestinationRepositoryImpl store = ref.read(
      destinationRepositoryProvider,
    );
    final Map<DestinationKind, CloudDestination> backends = await ref.read(
      cloudBackendsProvider.future,
    );
    return _runner ??= UploadRunner(
      destinationFor: (DestinationKind kind) {
        return resolveDestination(kind, backends);
      },
      history: store.history,
      clock: store.clock,
      beforeSend: ref.read(cloudExportGuardProvider),
    );
  }

  void _track(UploadProgress progress) {
    if (progress.attemptId.isEmpty || !ref.mounted) {
      return;
    }
    final bool moving =
        progress.outcome == 'sending' || progress.outcome == 'interrupted';
    state = <String, UploadProgress>{
      for (final MapEntry<String, UploadProgress> entry in state.entries)
        if (entry.key != progress.attemptId) entry.key: entry.value,
      if (moving) progress.attemptId: progress,
    };
  }

  UploadProgress _refused(LocalizedMessage reason) {
    return (
      attemptId: '',
      sent: 0,
      total: 0,
      outcome: 'failed',
      failureReason: reason.fallback,
      localizedFailure: reason,
    );
  }
}

/// The session's uploads. Kept alive so a transfer outlives its page.
final NotifierProvider<UploadController, Map<String, UploadProgress>>
uploadControllerProvider =
    NotifierProvider<UploadController, Map<String, UploadProgress>>(
      UploadController.new,
    );

/// Upload attempts newest first, updated as each starts and ends.
final StreamProvider<List<UploadAttempt>> uploadAttemptsProvider =
    StreamProvider.autoDispose<List<UploadAttempt>>((Ref ref) {
      return ref.watch(destinationRepositoryProvider).watchAttempts();
    });
