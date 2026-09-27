/// Duplicate candidates across a merge boundary only (task 019).
///
/// Local pairs are not reported again. [score] is the detector of task 110.
final class PostMergeScan {
  /// Incoming records scored against local ones. An empty list is a scan
  /// that found nothing.
  static List<ScanPair> scan({
    required List<ScanRecord> local,
    required List<ScanRecord> incoming,
    required double Function(ScanRecord local, ScanRecord incoming) score,
  }) {
    final List<ScanPair> pairs = <ScanPair>[];
    for (final ScanRecord arrived in incoming) {
      for (final ScanRecord here in local) {
        final double value = score(here, arrived);
        if (value > 0) {
          pairs.add((localId: here.id, incomingId: arrived.id, score: value));
        }
      }
    }
    return pairs;
  }
}

/// A record on one side of the boundary.
typedef ScanRecord = ({String id, String identity});

/// One candidate pair and its score.
typedef ScanPair = ({String localId, String incomingId, double score});
