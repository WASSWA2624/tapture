import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

/// Random access over every sample a capture has taken, so a reader can
/// fetch audio long after it was streamed.
abstract interface class PcmStore {
  /// Samples available, counted from the start of the take.
  int get length;

  /// A copy of samples `[from, to)`. A range outside `[0, length]` is a
  /// `ValidationFailure`; a closed store is a `StorageFailure`.
  Future<Result<Int16List>> read(int from, int to);
}
