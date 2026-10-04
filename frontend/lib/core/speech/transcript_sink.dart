import 'package:tapture/core/errors/result.dart';

import 'finished_utterance.dart';
import 'transcript_outcome.dart';

/// Where a live session writes its transcript, one utterance at a time
/// (spec §30.4.2). Features implement it over their own store.
///
/// Rule 4: a call completes successfully only once its write is durable, so
/// a session never reports words that a crash could lose.
abstract interface class TranscriptSink {
  /// Durably appends [utterance], segments and gap alike.
  Future<Result<void>> appendUtterance(FinishedUtterance utterance);

  /// Durably records how the transcript ended, complete or interrupted.
  Future<Result<void>> finish(TranscriptOutcome outcome);
}
