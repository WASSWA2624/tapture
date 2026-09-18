import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:tapture/core/constants/app_constants.dart';

/// Caps a photo's long edge so a feedback attach cannot hold a full-size
/// camera file in memory.
abstract final class FeedbackShotFit {
  /// [bytes] decoded and re-encoded as PNG at the feedback long edge.
  /// Returns [bytes] when they already fit or cannot be decoded.
  static Future<Uint8List> cap(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return bytes;
    }
    try {
      final int edge = AppConstants.userFeedback.screenshotLongEdge;
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: edge,
        targetHeight: edge,
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      try {
        final ui.Image image = frame.image;
        try {
          final ByteData? png = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (png == null) {
            return bytes;
          }
          return png.buffer.asUint8List();
        } finally {
          image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } on Object {
      return bytes;
    }
  }
}
