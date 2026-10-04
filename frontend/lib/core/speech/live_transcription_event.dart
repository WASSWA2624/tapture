import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/errors/failure.dart';

import 'live_transcription_phase.dart';
import 'transcript_segment.dart';
import 'transcription_warning_kind.dart';

part 'input_level_changed.dart';
part 'interim_transcript.dart';
part 'segment_finalized.dart';
part 'transcription_draining.dart';
part 'transcription_failed.dart';
part 'transcription_state_changed.dart';
part 'transcription_warning.dart';
part 'utterance_finalized.dart';

/// Something a live transcription session reports while it listens and
/// drains (spec §30.4.5).
///
/// Variants live in this library so the type can stay sealed while each
/// class keeps its own file. Interim text is display-only: never persisted
/// and never logged.
sealed class LiveTranscriptionEvent {
  /// Creates an event.
  const LiveTranscriptionEvent();
}
