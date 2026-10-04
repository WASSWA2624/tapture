import '../speech_decode_kind.dart';
import 'utterance_boundary.dart';

/// One decode the pipeline's scheduler hands out: the final of a closed
/// utterance or a draft of the open one (spec §30.4.7).
final class DecodeJob {
  /// The final of [utterance], over its decode range.
  DecodeJob.committed(UtteranceBoundary this.utterance)
    : kind = SpeechDecodeKind.committed,
      utteranceId = utterance.id,
      fromSample = utterance.decodeFromSample,
      toSample = utterance.endSample;

  /// A draft of open utterance [utteranceId] over samples
  /// `[fromSample, toSample)`.
  const DecodeJob.interim({
    required this.utteranceId,
    required this.fromSample,
    required this.toSample,
  }) : kind = SpeechDecodeKind.interim,
       utterance = null;

  /// Whether this is a final or a draft.
  final SpeechDecodeKind kind;

  /// The utterance decoded.
  final int utteranceId;

  /// The first sample read.
  final int fromSample;

  /// The sample after the last one read.
  final int toSample;

  /// The closed utterance a final decodes; null for a draft.
  final UtteranceBoundary? utterance;

  /// Samples the job reads.
  int get length => toSample - fromSample;
}
