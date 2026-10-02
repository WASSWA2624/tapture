import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'file_validation.dart';

/// Source format and encoded pixel bounds, without reencoding raw evidence.
final class ImageMetadata {
  const ImageMetadata._({
    required this.extension,
    required this.mimeType,
    required this.width,
    required this.height,
  });

  /// Canonical generated-file extension.
  final String extension;

  /// Media type matching the original bytes.
  final String mimeType;

  /// Encoded raster width; EXIF orientation remains on the original.
  final int width;

  /// Encoded raster height.
  final int height;

  /// Inspects decoder headers on a worker without allocating pixel frames.
  static Future<Result<ImageMetadata>> inspect(
    Uint8List bytes, {
    CancellationToken? cancel,
  }) => runIsolate(_inspect, bytes, cancel: cancel);
}

ImageMetadata _inspect(Uint8List bytes) {
  try {
    final String? extension = imageExtensionFromHeader(bytes);
    if (extension == null) throw const FormatException();
    validatePickedImage(
      name: 'photo.$extension',
      byteLength: bytes.length,
      header: bytes,
    ).getOrThrow();
    final image.Decoder decoder = switch (extension) {
      'jpg' => image.JpegDecoder(),
      'png' => image.PngDecoder(),
      'webp' => image.WebPDecoder(),
      _ => throw const FormatException(),
    };
    final image.DecodeInfo? info = decoder.startDecode(bytes);
    if (info == null || info.width < 1 || info.height < 1) {
      throw const FormatException();
    }
    return ImageMetadata._(
      extension: extension,
      mimeType: extension == 'jpg' ? 'image/jpeg' : 'image/$extension',
      width: info.width,
      height: info.height,
    );
  } on Failure {
    rethrow;
  } on Object {
    throw ValidationFailure(
      localizedMessage: Copy.messages.photoUnreadable,
      localizedRecovery: Copy.messages.photoUnreadableRecovery,
    );
  }
}
