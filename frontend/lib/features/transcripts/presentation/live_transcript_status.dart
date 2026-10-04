import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/speech/transcription_warning_kind.dart';

import 'transcript_mode.dart';
import 'transcript_session_phase.dart';

/// Where a surface's live transcript session stands, as its panel shows it.
/// The words themselves travel in the controller's frames, not here.
final class LiveTranscriptStatus {
  /// A session in [phase] recording in [mode].
  const LiveTranscriptStatus({
    this.phase = TranscriptSessionPhase.idle,
    this.mode = TranscriptMode.live,
    this.transcriptId,
    this.attachmentId,
    this.pauseReason,
    this.failure,
    this.retryable = false,
    this.warning,
    this.lag,
    this.unsaved = false,
    this.draining = false,
  });

  /// Nothing recording.
  static const LiveTranscriptStatus idle = LiveTranscriptStatus();

  /// Where the session stands.
  final TranscriptSessionPhase phase;

  /// Whether the session transcribes or only records.
  final TranscriptMode mode;

  /// The transcript row being written, once it exists.
  final String? transcriptId;

  /// The attachment the audio was filed as, once filed.
  final String? attachmentId;

  /// Why capture is paused, while [phase] is paused.
  final CapturePauseReason? pauseReason;

  /// What went wrong, when [phase] is failed or a control was refused.
  final Failure? failure;

  /// Whether a failed filing step can be tried again (`retrySave`).
  final bool retryable;

  /// The latest warning the session raised without stopping, if any.
  final TranscriptionWarningKind? warning;

  /// How far transcription lags behind the audio, with an `engineBehind`
  /// [warning].
  final Duration? lag;

  /// Whether transcript text is waiting to be saved.
  final bool unsaved;

  /// Whether the transcript is still being finished after the audio was
  /// saved.
  final bool draining;

  /// This status with the given parts replaced. The `clear` flags drop the
  /// failure, the pause reason and the warning.
  LiveTranscriptStatus copyWith({
    TranscriptSessionPhase? phase,
    TranscriptMode? mode,
    String? transcriptId,
    String? attachmentId,
    CapturePauseReason? pauseReason,
    Failure? failure,
    bool? retryable,
    TranscriptionWarningKind? warning,
    Duration? lag,
    bool? unsaved,
    bool? draining,
    bool clearPauseReason = false,
    bool clearFailure = false,
    bool clearWarning = false,
  }) {
    return LiveTranscriptStatus(
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      transcriptId: transcriptId ?? this.transcriptId,
      attachmentId: attachmentId ?? this.attachmentId,
      pauseReason: clearPauseReason ? null : pauseReason ?? this.pauseReason,
      failure: clearFailure ? null : failure ?? this.failure,
      retryable: retryable ?? this.retryable,
      warning: clearWarning ? null : warning ?? this.warning,
      lag: clearWarning ? null : lag ?? this.lag,
      unsaved: unsaved ?? this.unsaved,
      draining: draining ?? this.draining,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LiveTranscriptStatus &&
      other.phase == phase &&
      other.mode == mode &&
      other.transcriptId == transcriptId &&
      other.attachmentId == attachmentId &&
      other.pauseReason == pauseReason &&
      other.failure == failure &&
      other.retryable == retryable &&
      other.warning == warning &&
      other.lag == lag &&
      other.unsaved == unsaved &&
      other.draining == draining;

  @override
  int get hashCode => Object.hash(
    phase,
    mode,
    transcriptId,
    attachmentId,
    pauseReason,
    failure,
    retryable,
    warning,
    lag,
    unsaved,
    draining,
  );
}
