import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Produces a metadata-free, obscured PNG copy without changing its source.
abstract final class ImageRedaction {
  /// Obscures normalized [marks] off the UI isolate, failing closed.
  static Future<Result<Uint8List>> burn(
    Uint8List original,
    List<ImageRect> marks, {
    CancellationToken? cancel,
  }) => runIsolate<({Uint8List bytes, List<ImageRect> marks}), Uint8List>(
    _burn,
    (bytes: original, marks: marks),
    cancel: cancel,
  );
}

Uint8List _burn(({Uint8List bytes, List<ImageRect> marks}) job) {
  final img.Image? decoded = img.decodeImage(job.bytes);
  if (decoded == null) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThisPhotoCannotBeProtected,
    );
  }
  final img.Image upright = img.bakeOrientation(decoded);
  // Copy pixels into a fresh image: EXIF, GPS, comments and source metadata
  // must not survive into an outbound privacy derivative.
  final img.Image copy = img.Image(
    width: upright.width,
    height: upright.height,
  );
  img.compositeImage(copy, upright);
  for (final ImageRect mark in job.marks) {
    if (!mark.x.isFinite ||
        !mark.y.isFinite ||
        !mark.width.isFinite ||
        !mark.height.isFinite ||
        mark.x < 0 ||
        mark.y < 0 ||
        mark.width <= 0 ||
        mark.height <= 0 ||
        mark.x + mark.width > 1 ||
        mark.y + mark.height > 1) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureAHiddenAreaIsInvalid,
      );
    }
    final int left = (mark.x * copy.width).floor();
    final int top = (mark.y * copy.height).floor();
    final int right = ((mark.x + mark.width) * copy.width).ceil();
    final int bottom = ((mark.y + mark.height) * copy.height).ceil();
    img.fillRect(
      copy,
      x1: left,
      y1: top,
      x2: right - 1,
      y2: bottom - 1,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
  return img.encodePng(copy);
}

/// A rectangle relative to the upright image, with coordinates in 0–1.
typedef ImageRect = ({double x, double y, double width, double height});
