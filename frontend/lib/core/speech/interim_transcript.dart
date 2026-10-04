part of 'live_transcription_event.dart';

/// A draft of the utterance still being spoken. Display-only: never
/// persisted and never logged. The final for [utteranceId] supersedes it.
final class InterimTranscript extends LiveTranscriptionEvent {
  /// A draft of utterance [utteranceId] from [startSample]: [stable] words
  /// that later drafts only extend, then [tentative] words that may change.
  const InterimTranscript({
    required this.utteranceId,
    required this.startSample,
    required this.stable,
    required this.tentative,
  });

  /// The utterance this drafts.
  final int utteranceId;

  /// The first sample the draft covers on the session timeline.
  final int startSample;

  /// Words two drafts agreed on; append-only within the utterance.
  final String stable;

  /// The rest of the latest draft.
  final String tentative;
}
