import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Orientation-corrected JPEG resizing shared by upload copies and thumbnails.
abstract final class ImageResize {
  /// Fits [bytes] within [longEdge] without enlarging them, off the UI isolate.
  static Future<Result<Uint8List>> fit(
    Uint8List bytes, {
    required int longEdge,
    required int quality,
    CancellationToken? cancel,
  }) {
    return runIsolate(_resize, (
      bytes: bytes,
      edge: longEdge,
      quality: quality,
    ), cancel: cancel);
  }
}

Uint8List _resize(({Uint8List bytes, int edge, int quality}) job) {
  if (job.edge < 1 || job.quality < 1 || job.quality > 100) {
    throw const ValidationFailure(message: 'That image size is not valid.');
  }
  final img.Image? decoded = img.decodeImage(job.bytes);
  if (decoded == null) {
    throw const StorageFailure(
      message: 'That photo could not be read as an image.',
      recoveryAction: 'Capture the photo again, then try again.',
    );
  }
  IsolateRunner.reportProgress(0.3);
  img.Image output = img.bakeOrientation(decoded);
  final int longest = output.width > output.height
      ? output.width
      : output.height;
  if (longest > job.edge) {
    final double scale = job.edge / longest;
    output = img.copyResize(
      output,
      width: (output.width * scale).round().clamp(1, output.width),
      height: (output.height * scale).round().clamp(1, output.height),
      interpolation: img.Interpolation.linear,
    );
  }
  IsolateRunner.reportProgress(0.8);
  final Uint8List encoded = Uint8List.fromList(
    img.encodeJpg(output, quality: job.quality),
  );
  IsolateRunner.reportProgress(1);
  return encoded;
}
