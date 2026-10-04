import 'dart:async';

import 'package:tapture/core/errors/result.dart';

import 'speech_decode_kind.dart';
import 'speech_decode_request.dart';
import 'speech_decode_result.dart';

/// One decode request waiting on, or running in, a platform engine's queue.
/// Shared by the native and browser engines; never exported by the barrel.
final class SpeechDecodeJob {
  /// Queues [request] for lease [leaseId].
  SpeechDecodeJob(this.leaseId, this.request);

  /// The lease that asked for this decode.
  final int leaseId;

  /// The window to decode.
  final SpeechDecodeRequest request;

  /// Completes once with the job's outcome.
  final Completer<Result<SpeechDecodeResult>> done =
      Completer<Result<SpeechDecodeResult>>();

  /// Assigned when the job is sent to a worker; 0 while it waits.
  int jobId = 0;

  /// Whether the job was aborted, so a late result is discarded.
  bool aborted = false;

  /// Unregisters the caller's cancellation listener, once.
  void Function()? detach;

  /// Whether this is a final rather than a disposable draft.
  bool get committed => request.kind == SpeechDecodeKind.committed;

  /// Completes the job with [result] unless it already completed.
  void finish(Result<SpeechDecodeResult> result) {
    detach?.call();
    detach = null;
    if (!done.isCompleted) {
      done.complete(result);
    }
  }
}
