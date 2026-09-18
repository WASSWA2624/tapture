import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:tapture/core/constants/app_constants.dart';

/// Caps a photo's long edge so a feedback attach never holds a full-size
/// camera file in memory. Desktop pickers cannot scale, so this is the
/// guarantee every platform shares.
abstract final class FeedbackShotFit {
  /// [bytes] scaled so neither side passes the feedback long edge, keeping
  /// the aspect ratio. Returned untouched when they already fit or cannot
  /// be decoded; only the header is read to decide.
  static Future<Uint8List> cap(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return bytes;
    }
    final int edge = AppConstants.userFeedback.screenshotLongEdge;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
        bytes,
      );
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      buffer.dispose();
      final int width = descriptor.width;
      final int height = descriptor.height;
      if (width <= edge && height <= edge) {
        return bytes;
      }
      // One side only, so the codec keeps the aspect ratio.
      codec = await descriptor.instantiateCodec(
        targetWidth: width >= height ? edge : null,
        targetHeight: width >= height ? null : edge,
      );
      final ui.Image image = (await codec.getNextFrame()).image;
      try {
        final ByteData? png = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        return png?.buffer.asUint8List() ?? bytes;
      } finally {
        image.dispose();
      }
    } on Object {
      return bytes;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
    }
  }
}
