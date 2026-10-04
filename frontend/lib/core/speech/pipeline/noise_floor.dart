import 'dart:collection';

/// The quietest frame level of the last stretch of audio, so the energy
/// gate knows what silence sounds like in this room (spec §30.4.7).
///
/// A sliding minimum kept in a monotonic queue: each frame is added once
/// and dropped at most once, so the cost per frame is constant.
final class NoiseFloor {
  /// A floor over the last [spanSamples] samples.
  NoiseFloor({required this.spanSamples});

  /// The span, in samples, the floor looks back over.
  final int spanSamples;

  final ListQueue<({int start, double dbfs})> _frames =
      ListQueue<({int start, double dbfs})>();

  /// The quietest level, in dBFS, of the frames that started within the
  /// span before the latest one; infinite before any frame.
  double get dbfs => _frames.isEmpty ? double.infinity : _frames.first.dbfs;

  /// Adds the frame starting at sample [start] with level [dbfs]. Frames
  /// are added in time order.
  void add(int start, double dbfs) {
    while (_frames.isNotEmpty && _frames.last.dbfs >= dbfs) {
      _frames.removeLast();
    }
    _frames.addLast((start: start, dbfs: dbfs));
    while (_frames.first.start <= start - spanSamples) {
      _frames.removeFirst();
    }
  }
}
