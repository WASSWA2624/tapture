import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Orientation-corrected JPEG resizing shared by upload copies and thumbnails.
abstract final class ImageResize {
  /// Versioned identity for an upright upload copy with no source metadata.
  static String uploadCacheKey(
    String sourceHash, {
    int longEdge = AppConstants.imageLongEdge,
    int? quality,
  }) =>
      '${sourceHash}_${longEdge}_${quality ?? AppConstants.images.quality}_v2';

  /// A bounded upright bitmap and dimensions for normalized photo editing.
  static Future<Result<({Uint8List bytes, int width, int height})>> preview(
    Uint8List bytes, {
    int longEdge = AppConstants.imageLongEdge,
    CancellationToken? cancel,
  }) => runIsolate(_preview, (bytes: bytes, edge: longEdge), cancel: cancel);

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

({Uint8List bytes, int width, int height}) _preview(
  ({Uint8List bytes, int edge}) job,
) {
  if (job.edge < 1) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatImageSizeIsNotValid,
    );
  }
  final img.Image? decoded = img.decodeImage(job.bytes);
  if (decoded == null) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThisPhotoCannotBeMarked,
    );
  }
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
  _stripMetadata(output);
  return (
    bytes: img.encodePng(output),
    width: output.width,
    height: output.height,
  );
}

Uint8List _resize(({Uint8List bytes, int edge, int quality}) job) {
  if (job.edge < 1 || job.quality < 1 || job.quality > 100) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatImageSizeIsNotValid,
    );
  }
  final img.Image? decoded = img.decodeImage(job.bytes);
  if (decoded == null) {
    throw StorageFailure(
      localizedMessage: Copy.messages.failureThatPhotoCouldNotBeReadAs,
      localizedRecovery: Copy.messages.failureCaptureThePhotoAgainThenTryAgain,
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
  _stripMetadata(output);
  IsolateRunner.reportProgress(0.8);
  final Uint8List encoded = Uint8List.fromList(
    img.encodeJpg(output, quality: job.quality),
  );
  IsolateRunner.reportProgress(1);
  return encoded;
}

void _stripMetadata(img.Image image) {
  image
    ..exif = img.ExifData()
    ..iccProfile = null
    ..textData = null;
}
