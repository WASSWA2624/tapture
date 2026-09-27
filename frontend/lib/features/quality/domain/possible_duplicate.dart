import 'duplicate_signal.dart';

/// An incoming record that may duplicate one already on this device (task
/// 076, W22). Named apart from the stored `duplicates` row, which a pair
/// becomes only once a person has seen it.
final class PossibleDuplicate {
  /// Creates a pair.
  const PossibleDuplicate({
    required this.incomingId,
    required this.localId,
    required this.signal,
    required this.score,
  });

  /// The record the package would bring in.
  final String incomingId;

  /// The record already on this device.
  final String localId;

  /// The strongest reason the two look alike.
  final DuplicateSignal signal;

  /// How strongly, 0–1.
  final double score;
}
