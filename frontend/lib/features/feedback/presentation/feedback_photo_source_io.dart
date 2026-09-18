import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'feedback_photo_source.dart';

/// Native builds keep screenshot capture; a camera plugin is not on the
/// allowlist, so a pick explains what to do instead.
FeedbackPhotoSource platformPhotoSource() => const _DevicePhotos();

final class _DevicePhotos implements FeedbackPhotoSource {
  const _DevicePhotos();

  @override
  Future<Result<List<Uint8List>>> pick({required bool camera}) async {
    return const FailureResult<List<Uint8List>>(
      ValidationFailure(
        message: Copy.feedbackPhotoFailed,
        recoveryAction:
            'Add a screenshot of this screen from Feedback, or use the web app to choose a photo.',
      ),
    );
  }
}
