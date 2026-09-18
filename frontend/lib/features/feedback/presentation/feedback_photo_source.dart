import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'feedback_photo_source_stub.dart'
    if (dart.library.io) 'feedback_photo_source_io.dart'
    if (dart.library.js_interop) 'feedback_photo_source_web.dart'
    as platform;

/// Camera and library photos for a feedback draft. Reached only through this
/// type so tests never open a picker (FE-STR-11, FE-TEST-03).
abstract interface class FeedbackPhotoSource {
  /// The picker for this platform.
  factory FeedbackPhotoSource() => platform.platformPhotoSource();

  /// A stand-in that returns [photos] on every pick.
  factory FeedbackPhotoSource.fake({
    List<Uint8List> photos = const <Uint8List>[],
    bool fail = false,
  }) {
    return _FakePhotoSource(photos: photos, fail: fail);
  }

  /// One or more images from the library, or one from the camera when
  /// [camera] is true. An empty list means nothing was chosen.
  Future<Result<List<Uint8List>>> pick({required bool camera});
}

final class _FakePhotoSource implements FeedbackPhotoSource {
  _FakePhotoSource({required this.photos, required this.fail});

  final List<Uint8List> photos;
  final bool fail;

  @override
  Future<Result<List<Uint8List>>> pick({required bool camera}) async {
    if (fail) {
      return const FailureResult<List<Uint8List>>(
        ValidationFailure(
          message: Copy.feedbackPhotoFailed,
          recoveryAction: 'Choose another photo or attach a screenshot.',
        ),
      );
    }
    return Success<List<Uint8List>>(List<Uint8List>.of(photos));
  }
}
