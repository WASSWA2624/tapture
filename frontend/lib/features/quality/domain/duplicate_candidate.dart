import 'duplicate_signal.dart';

/// One record that may be the same thing as the record being saved (task 015).
///
/// A proposal only. Detection never writes a resolution.
final class DuplicateCandidate {
  /// Creates a candidate for [recordId].
  const DuplicateCandidate(this.recordId, this.score, this.signals);

  /// The existing record.
  final String recordId;

  /// How close the match is, from 0 to 1. Higher is closer.
  final double score;

  /// Every signal that fired.
  final Set<DuplicateSignal> signals;
}
