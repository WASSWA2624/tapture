/// Per-project record number allocator. Call inside the same transaction
/// as the record insert so numbers have no gaps or collisions.
abstract final class RecordNumber {
  /// Next number after [lastAllocated] (0 when none yet).
  static int next(int lastAllocated) {
    if (lastAllocated < 0) {
      return 1;
    }
    return lastAllocated + 1;
  }

  /// Allocates [count] consecutive numbers starting after [lastAllocated].
  static List<int> allocateRange(int lastAllocated, int count) {
    final int start = next(lastAllocated);
    return <int>[for (var i = 0; i < count; i++) start + i];
  }
}
