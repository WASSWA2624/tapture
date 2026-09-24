import 'package:tapture/core/errors/result.dart';

import 'capture_session.dart';

/// Transaction boundary that freezes one capture session into a raw record.
abstract interface class CaptureRecordPersistence {
  /// Persists every raw value and evidence link atomically.
  Future<Result<String>> persist(CaptureSession session);
}
