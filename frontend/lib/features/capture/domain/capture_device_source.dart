import 'package:tapture/features/templates/domain/domain.dart';

import 'capture_session.dart';

/// Fresh local device values for one explicitly opted-in Capture owner.
abstract interface class CaptureDeviceSource {
  /// Invalidates the previous owner and starts an eligible background read.
  void bind(CaptureSession session, Iterable<FieldDef> fields);

  /// Refreshes the current eligible owner without delaying Capture.
  void refresh();

  /// The latest completed fresh reading, only for its still-current owner.
  String? snapshot(CaptureSession session);

  /// Reading completion, invalidation and expiry notifications.
  Stream<void> get changes;

  /// Invalidates pending reads and releases owned resources.
  void dispose();
}
