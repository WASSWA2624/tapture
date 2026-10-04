import 'package:tapture/core/errors/failure.dart';

import 'speech_selection.dart';
import 'speech_verdict.dart';

/// The outcome of model selection: a [verdict], the [selection] when it is
/// ready, and otherwise the [failure] to show (spec §30.4.4).
final class SpeechAvailability {
  /// Describes one selection outcome. [reason] is metadata for the log,
  /// never speech or a path.
  const SpeechAvailability({
    required this.verdict,
    this.selection,
    this.failure,
    this.reason = '',
  });

  /// Whether speech can run, or why not.
  final SpeechVerdict verdict;

  /// The models, threads and profiles to use; set only when ready.
  final SpeechSelection? selection;

  /// What to tell the operator; set unless ready.
  final Failure? failure;

  /// Why this verdict, in a few words.
  final String reason;

  /// Whether a model is chosen and can be loaded.
  bool get ready => verdict == SpeechVerdict.ready && selection != null;
}
