import 'package:flutter/widgets.dart';

/// Optional native preview supplied by a camera adapter.
abstract interface class CameraPreviewSurface {
  /// The live image; plugin-specific widgets remain inside core.
  Widget buildPreview();
}
