import 'package:tapture/core/errors/failure.dart';

import 'speech_availability.dart';
import 'speech_selection.dart';
import 'speech_verdict.dart';

/// Whether on-device speech is ready for the voice language, as screens and
/// dictation read it (spec §30.4.2).
final class SpeechReadiness {
  /// Describes readiness. A null [verdict] means not checked yet.
  const SpeechReadiness({
    this.verdict,
    this.selection,
    this.failure,
    this.reason = '',
  });

  /// The host's [availability] as readiness.
  factory SpeechReadiness.from(SpeechAvailability availability) =>
      SpeechReadiness(
        verdict: availability.verdict,
        selection: availability.selection,
        failure: availability.failure,
        reason: availability.reason,
      );

  /// Not checked yet: nothing may rely on the engine.
  static const SpeechReadiness notReady = SpeechReadiness();

  /// The last verdict, or null before the first check.
  final SpeechVerdict? verdict;

  /// The model, threads and profiles chosen, when ready.
  final SpeechSelection? selection;

  /// What to tell the operator when not ready, once checked.
  final Failure? failure;

  /// Why, in a few words, for diagnostics.
  final String reason;

  /// Whether a model is chosen and can be loaded.
  bool get ready => verdict == SpeechVerdict.ready && selection != null;
}
