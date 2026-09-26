import 'package:tapture/core/errors/result.dart';

import 'capture_session.dart';

/// Transaction boundary that freezes one capture session into a raw record,
/// and that later loads and updates that record's evidence (FBK0000148).
abstract interface class CaptureRecordPersistence {
  /// Persists every raw value and evidence link atomically.
  Future<Result<String>> persist(CaptureSession session);

  /// A session that edits [recordId]: its live photos in tray order, derived
  /// versions included, its audio, and its captions keyed by photo id and
  /// `''`, refined text first. [CaptureSession.editing] is true.
  Future<Result<CaptureSession>> load(String recordId);

  /// Writes what [edited] changed on its record in one transaction: added
  /// photos are filed, removed ones tombstoned with their files kept,
  /// changed captions refined beside their raw text, new captions inserted,
  /// and new audio linked. Template, context, status and field values stay.
  Future<Result<void>> update(CaptureSession edited);
}
