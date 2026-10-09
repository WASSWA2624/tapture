import 'package:tapture/core/errors/result.dart';

import 'capture_persistence.dart';
import 'capture_session.dart';

/// Session writes whose durable owner must still match the originating form.
abstract interface class OwnedCapturePersistence implements CapturePersistence {
  /// Atomically updates an existing session owned by [owner].
  ///
  /// Both the candidate and durable session must match the complete tuple.
  /// Missing, unreadable or changed owners are refused without a write.
  Future<Result<void>> saveOwnedSession(
    CaptureSession session, {
    required ({String sessionId, String templateId, int? templateVersion})
    owner,
  });
}
