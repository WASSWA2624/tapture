import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Where a photo sits when it is drawn to fit inside a box, so crop, draw and
/// type-on measure against the photo rather than the whole frame
/// (FBK0000150).
abstract final class PhotoFrame {
  /// The stored pixel size of encoded [bytes], read from the header without
  /// decoding the pixels. Null when [bytes] are not an image.
  static Future<Size?> sizeOf(Uint8List bytes) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return Size(descriptor.width.toDouble(), descriptor.height.toDouble());
    } on Object {
      return null;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  /// The rect [photo] occupies, centred and contained in [box], after
  /// [quarterTurns] clockwise quarter turns. [photo] is the stored pixel size;
  /// its sides swap for odd turns. An empty size gives an empty rect at the
  /// box centre.
  static Rect fit(Size box, Size photo, int quarterTurns) {
    final Size shown = quarterTurns.isOdd
        ? Size(photo.height, photo.width)
        : photo;
    final Rect bounds = Offset.zero & box;
    if (shown.isEmpty || box.isEmpty) {
      return Rect.fromCenter(center: bounds.center, width: 0, height: 0);
    }
    final FittedSizes sizes = applyBoxFit(BoxFit.contain, shown, box);
    return Alignment.center.inscribe(sizes.destination, bounds);
  }

  /// The quarter turns for [rotationDegrees], from 0 to 3.
  static int quarterTurns(int rotationDegrees) {
    return ((rotationDegrees % 360) + 360) % 360 ~/ 90;
  }

  /// The shortest crop side, as a fraction of the photo side.
  static const double minCropSide = 0.1;

  /// [fraction] moved by [delta], both fractions of the photo, kept inside
  /// the photo.
  static Rect move(Rect fraction, Offset delta) {
    final double left = (fraction.left + delta.dx).clamp(
      0.0,
      1 - fraction.width,
    );
    final double top = (fraction.top + delta.dy).clamp(
      0.0,
      1 - fraction.height,
    );
    return Rect.fromLTWH(left, top, fraction.width, fraction.height);
  }

  /// [fraction] with its [corner] dragged by [delta], both fractions of the
  /// photo. Each side stays at least [minCropSide] and inside the photo.
  static Rect resize(Rect fraction, Alignment corner, Offset delta) {
    double left = fraction.left;
    double top = fraction.top;
    double right = fraction.right;
    double bottom = fraction.bottom;
    if (corner.x < 0) {
      left = (left + delta.dx).clamp(0.0, right - minCropSide);
    } else {
      right = (right + delta.dx).clamp(left + minCropSide, 1.0);
    }
    if (corner.y < 0) {
      top = (top + delta.dy).clamp(0.0, bottom - minCropSide);
    } else {
      bottom = (bottom + delta.dy).clamp(top + minCropSide, 1.0);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// [delta] in logical pixels as a fraction of [photo]'s shown size.
  static Offset fractionOf(Offset delta, Rect photo) {
    if (photo.width <= 0 || photo.height <= 0) {
      return Offset.zero;
    }
    return Offset(delta.dx / photo.width, delta.dy / photo.height);
  }

  /// [fraction] of [photo] as a rect in the same space as [photo].
  static Rect toRect(Rect fraction, Rect photo) {
    return Rect.fromLTWH(
      photo.left + fraction.left * photo.width,
      photo.top + fraction.top * photo.height,
      fraction.width * photo.width,
      fraction.height * photo.height,
    );
  }
}
