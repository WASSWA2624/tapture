import 'package:tapture/core/db/vector_relation.dart';

/// One entity's version vector (task 019). Comparison is [compareVectors].
final class VersionVector {
  /// Creates a vector. [counters] maps a device id to the revision seen.
  const VersionVector(this.counters);

  /// Device id to the highest revision seen from that device.
  final Map<String, int> counters;

  /// Bumps this device's counter by one. Other devices stay as they are.
  VersionVector increment(String deviceId) {
    return VersionVector(<String, int>{
      ...counters,
      deviceId: (counters[deviceId] ?? 0) + 1,
    });
  }

  /// The later revision of each device.
  VersionVector merge(VersionVector other) {
    final Map<String, int> next = <String, int>{...counters};
    for (final MapEntry<String, int> entry in other.counters.entries) {
      final int local = next[entry.key] ?? 0;
      if (entry.value > local) {
        next[entry.key] = entry.value;
      }
    }
    return VersionVector(next);
  }

  /// How this vector sits against [other].
  VectorRelation compareTo(VersionVector other) {
    return compareVectors(counters, other.counters);
  }
}
