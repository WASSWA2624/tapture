import 'package:tapture/core/ids/uuid_service.dart';

import 'capture_session.dart';

/// After a save, clears session-scoped evidence while keeping context,
/// pinned template and camera settings for the next item.
abstract final class CaptureReset {
  /// Fresh session sharing no mutable state with [previous].
  static CaptureSession next({
    required CaptureSession previous,
    required IdService ids,
  }) {
    return CaptureSession(
      id: ids.newId(),
      projectId: previous.projectId,
      templateId: previous.templateId,
      contextSnapshot: Map<String, String>.of(previous.contextSnapshot),
    );
  }
}
