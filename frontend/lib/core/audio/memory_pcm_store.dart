import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'pcm_store.dart';

/// A [PcmStore] in memory, for a capture that keeps nothing on disk, such as
/// field dictation. Bounded by [maxSamples].
final class MemoryPcmStore implements PcmStore {
  /// A store that keeps at most [maxSamples] samples.
  MemoryPcmStore({required this.maxSamples});

  /// The most samples this store keeps.
  final int maxSamples;

  /// Grown by doubling, never past [maxSamples].
  Int16List _samples = Int16List(0);
  int _length = 0;
  bool _closed = false;

  @override
  int get length => _length;

  /// Whether [count] more samples still fit.
  bool fits(int count) => _length + count <= maxSamples;

  /// Appends [samples]. False, and nothing kept, when they do not fit.
  bool append(Int16List samples) {
    if (_closed || !fits(samples.length)) {
      return false;
    }
    final int needed = _length + samples.length;
    if (needed > _samples.length) {
      final Int16List grown = Int16List(
        math.min(maxSamples, math.max(needed, _samples.length * 2)),
      );
      grown.setRange(0, _length, _samples);
      _samples = grown;
    }
    _samples.setRange(_length, needed, samples);
    _length = needed;
    return true;
  }

  @override
  Future<Result<Int16List>> read(int from, int to) async {
    if (_closed) {
      return const FailureResult<Int16List>(StorageFailure());
    }
    if (from < 0 || to < from || to > _length) {
      return const FailureResult<Int16List>(ValidationFailure());
    }
    return Success<Int16List>(_samples.sublist(from, to));
  }

  /// Frees the samples; later reads fail.
  void close() {
    _closed = true;
    _samples = Int16List(0);
  }
}
