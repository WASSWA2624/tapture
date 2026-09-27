/// How two version vectors sit relative to each other (task 061).
enum VectorRelation {
  /// The local vector is ahead on every device, and strictly ahead on one.
  dominates,

  /// The incoming vector is ahead on every device, and strictly ahead on one.
  dominated,

  /// Each side has a device the other has not caught up with.
  concurrent,

  /// Both maps name the same revisions.
  equal,
}

/// Classifies [mine] against [theirs]. Concurrent is reported, never resolved.
///
/// A missing device counts as revision 0. An empty vector is [dominated]
/// by any non-empty one. Two empty vectors are [equal].
VectorRelation compareVectors(Map<String, int> mine, Map<String, int> theirs) {
  final Set<String> devices = <String>{...mine.keys, ...theirs.keys};
  var mineGreater = false;
  var theirsGreater = false;
  for (final String device in devices) {
    final int local = mine[device] ?? 0;
    final int incoming = theirs[device] ?? 0;
    if (local > incoming) {
      mineGreater = true;
    }
    if (incoming > local) {
      theirsGreater = true;
    }
  }
  if (!mineGreater && !theirsGreater) {
    return VectorRelation.equal;
  }
  if (mineGreater && !theirsGreater) {
    return VectorRelation.dominates;
  }
  if (theirsGreater && !mineGreater) {
    return VectorRelation.dominated;
  }
  return VectorRelation.concurrent;
}
