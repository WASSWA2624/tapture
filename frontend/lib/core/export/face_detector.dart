import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as ml;
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'face_blur.dart';

/// On-device face discovery; unsupported platforms never report a false zero.
class FaceDetector {
  /// Creates the native detector facade.
  const FaceDetector();

  /// Reports native face rectangles or a recoverable failure.
  Future<Result<List<FaceRect>>> detect(
    Uint8List bytes, {
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<List<FaceRect>>(CancelledFailure());
    }
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return FailureResult<List<FaceRect>>(
        ValidationFailure(
          localizedMessage:
              Copy.messages.failureFaceDetectionIsUnavailableOnThisDevice,
          localizedRecovery: Copy.messages.failureUseAnAndroidOrIOSDeviceTo,
        ),
      );
    }
    final Result<_Bitmap> bitmap = await runIsolate<Uint8List, _Bitmap>(
      _decode,
      bytes,
      cancel: cancel,
    );
    if (bitmap case FailureResult<_Bitmap>(:final Failure failure)) {
      return FailureResult<List<FaceRect>>(failure);
    }
    final _Bitmap image = (bitmap as Success<_Bitmap>).value;
    final ml.FaceDetector detector = ml.FaceDetector(
      options: ml.FaceDetectorOptions(
        performanceMode: ml.FaceDetectorMode.accurate,
      ),
    );
    try {
      final List<ml.Face> faces = await detector.processImage(
        ml.InputImage.fromBitmap(
          bitmap: image.bytes,
          width: image.width,
          height: image.height,
        ),
      );
      if (cancel?.isCancelled ?? false) {
        return const FailureResult<List<FaceRect>>(CancelledFailure());
      }
      return Success<List<FaceRect>>(<FaceRect>[
        for (final ml.Face face in faces)
          if (face.boundingBox.right > 0 &&
              face.boundingBox.bottom > 0 &&
              face.boundingBox.left < image.width &&
              face.boundingBox.top < image.height)
            (
              x: face.boundingBox.left.floor().clamp(0, image.width),
              y: face.boundingBox.top.floor().clamp(0, image.height),
              width:
                  face.boundingBox.right.ceil().clamp(0, image.width) -
                  face.boundingBox.left.floor().clamp(0, image.width),
              height:
                  face.boundingBox.bottom.ceil().clamp(0, image.height) -
                  face.boundingBox.top.floor().clamp(0, image.height),
            ),
      ]);
    } on Object catch (error) {
      return FailureResult<List<FaceRect>>(Failure.from(error));
    } finally {
      await detector.close();
    }
  }
}

typedef _Bitmap = ({Uint8List bytes, int width, int height});

_Bitmap _decode(Uint8List bytes) {
  final img.Image? source = img.decodeImage(bytes);
  if (source == null) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThisPhotoCannotBeCheckedForFaces,
    );
  }
  final img.Image image = img.bakeOrientation(source);
  return (
    bytes: image.getBytes(order: img.ChannelOrder.rgba),
    width: image.width,
    height: image.height,
  );
}
