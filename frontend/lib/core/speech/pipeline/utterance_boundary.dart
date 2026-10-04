import 'utterance_end_reason.dart';
import 'utterance_evidence.dart';

/// One closed utterance on the session timeline (spec §30.4.7).
///
/// Utterances are ordered and at most the maximum utterance length plus
/// the seam overlap long. Two overlap only across a hard cut: the one
/// after it starts [seamFromSample], exactly the seam overlap before the
/// cut, and decodes that audio again so the seam can be aligned.
final class UtteranceBoundary {
  /// Utterance [id] over samples `[startSample, endSample)`, closed for
  /// [reason], with what the detector saw as [evidence].
  const UtteranceBoundary({
    required this.id,
    required this.startSample,
    required this.endSample,
    required this.reason,
    required this.evidence,
    this.seamFromSample,
  });

  /// The utterance's place in the session, from the segmenter's first id.
  final int id;

  /// First sample of the utterance.
  final int startSample;

  /// Sample after the utterance's last one.
  final int endSample;

  /// Why the utterance closed.
  final UtteranceEndReason reason;

  /// Where the re-decoded overlap begins when this utterance follows a
  /// hard cut; null otherwise.
  final int? seamFromSample;

  /// The detector's probability and the level of every frame overlapping
  /// the utterance.
  final UtteranceEvidence evidence;

  /// The first sample a decode of this utterance reads.
  int get decodeFromSample => seamFromSample ?? startSample;

  /// Samples in the utterance.
  int get length => endSample - startSample;
}
