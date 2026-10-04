import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/errors/result.dart';

import 'cancelled_transcription.dart';
import 'live_transcription_event.dart';
import 'live_transcription_phase.dart';
import 'live_transcription_result.dart';
import 'stopped_capture.dart';

/// One live transcription from start to its finished transcript (spec
/// §30.4.5): the microphone streams into a durable take while the speech
/// engine transcribes it.
///
/// [stop] returns as soon as the audio is published; the transcript keeps
/// draining under the service, whoever listens, and [done] completes once
/// it is written. Nothing on a save path waits for the drain (Rule 3).
abstract interface class LiveTranscriptionSession {
  /// What the session reports. Each listener first receives the current
  /// phase, then everything from then on.
  Stream<LiveTranscriptionEvent> get events;

  /// Where the session stands.
  LiveTranscriptionPhase get phase;

  /// Why capture is paused, while [phase] is paused.
  CapturePauseReason? get pauseReason;

  /// Pauses capture at the operator's request; the take is checkpointed.
  Future<Result<void>> pause();

  /// Resumes after any pause, re-checking the microphone permission. A
  /// revoked permission keeps the session paused as `permissionRevoked`.
  /// The session never resumes by itself.
  Future<Result<void>> resume();

  /// Stops capture and publishes the take; completes once it is published.
  /// The transcript keeps draining. Calling again returns the same stop.
  Future<Result<StoppedCapture>> stop();

  /// Completes after the drain, or a skip, once the sink has recorded how
  /// the transcript ended. Fails when the session was cancelled or failed.
  Future<Result<LiveTranscriptionResult>> get done;

  /// Ends the drain early: audio still waiting for its final stays
  /// untranscribed, past the result's `coveredToSample`.
  void skipRemaining();

  /// Abandons the session: the staged take is kept byte-for-byte and
  /// unpublished (§8.1 rule 1), and no transcript is returned.
  Future<Result<CancelledTranscription>> cancel();
}
