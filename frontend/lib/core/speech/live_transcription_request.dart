import 'package:flutter/foundation.dart';

import 'transcript_sink.dart';
import 'transcription_kind.dart';

/// What a live transcription session records and transcribes (spec
/// §30.4.5).
final class LiveTranscriptionRequest {
  /// A [kind] session transcribing [languageTag] (a BCP 47 tag).
  ///
  /// A long-form session publishes its take at [audioPath] (relative to
  /// the storage root) and writes its transcript to [sink], numbering
  /// segments from [nextSegmentId]; with [transcribe] false it only
  /// records. Dictation is memory-only and ignores [audioPath].
  /// [interims] asks for drafts of the utterance being spoken.
  /// [autoStopAfterSilence] and [maxDuration] stop the session by
  /// themselves (dictation defaults to `AppConstants.dictation`'s
  /// `pauseFor` and `listenFor`). [onPreempted] runs when evidence capture
  /// takes the microphone from dictation, which then stops.
  const LiveTranscriptionRequest({
    required this.kind,
    required this.languageTag,
    this.audioPath,
    this.sink,
    this.nextSegmentId = 1,
    this.transcribe = true,
    this.interims = true,
    this.autoStopAfterSilence,
    this.maxDuration,
    this.onPreempted,
  });

  /// Dictation or a long-form recording.
  final TranscriptionKind kind;

  /// The BCP 47 tag of the language spoken.
  final String languageTag;

  /// Where a long-form take is published, relative to the storage root.
  final String? audioPath;

  /// Where finished utterances are written, or null to keep them in the
  /// result only.
  final TranscriptSink? sink;

  /// The id of the first segment, after any already stored.
  final int nextSegmentId;

  /// Whether to transcribe; false records only.
  final bool transcribe;

  /// Whether to draft the utterance being spoken.
  final bool interims;

  /// Silence after which the session stops by itself, or null.
  final Duration? autoStopAfterSilence;

  /// Audio after which the session stops by itself, or null.
  final Duration? maxDuration;

  /// Called when evidence capture takes the microphone.
  final VoidCallback? onPreempted;
}
