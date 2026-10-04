import 'dart:math' as math;
import 'dart:typed_data';

/// The most recent samples of a take, held in a fixed buffer so recent
/// audio is read back without touching the disk.
final class PcmRing {
  /// A ring holding the last [capacity] samples of a take whose first
  /// [origin] samples were never added.
  PcmRing(int capacity, {int origin = 0})
    : _buffer = Int16List(math.max(1, capacity)),
      _origin = origin,
      _length = origin;

  final Int16List _buffer;
  final int _origin;
  int _length;

  /// The most samples held at once.
  int get capacity => _buffer.length;

  /// Samples ever added; the index one past the newest.
  int get length => _length;

  /// Index of the oldest sample still held.
  int get start => math.max(_origin, _length - _buffer.length);

  /// Whether every sample in `[from, to)` is still held.
  bool holds(int from, int to) => from >= start && to <= _length && from <= to;

  /// Appends [samples], dropping the oldest when full.
  void add(Int16List samples) {
    final int count = samples.length;
    final int keep = math.min(count, _buffer.length);
    var position = (_length + count - keep) % _buffer.length;
    var source = count - keep;
    while (source < count) {
      final int run = math.min(count - source, _buffer.length - position);
      _buffer.setRange(position, position + run, samples, source);
      source += run;
      position = (position + run) % _buffer.length;
    }
    _length += count;
  }

  /// A copy of `[from, to)`, which must satisfy [holds].
  Int16List read(int from, int to) {
    if (!holds(from, to)) {
      throw RangeError('Samples $from to $to are not held.');
    }
    final Int16List out = Int16List(to - from);
    var index = 0;
    var position = from % _buffer.length;
    while (index < out.length) {
      final int run = math.min(out.length - index, _buffer.length - position);
      out.setRange(index, index + run, _buffer, position);
      index += run;
      position = (position + run) % _buffer.length;
    }
    return out;
  }
}
