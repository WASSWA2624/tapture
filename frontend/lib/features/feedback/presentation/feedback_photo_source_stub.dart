import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

import 'feedback_photo_source.dart';

/// Neither a camera nor a library: every pick is empty.
FeedbackPhotoSource platformPhotoSource() => const _NoPhotos();

final class _NoPhotos implements FeedbackPhotoSource {
  const _NoPhotos();

  @override
  Future<Result<List<Uint8List>>> pick({required bool camera}) async {
    return const Success<List<Uint8List>>(<Uint8List>[]);
  }
}
