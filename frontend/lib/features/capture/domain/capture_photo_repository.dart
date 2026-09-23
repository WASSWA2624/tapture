import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

import 'photo_draft.dart';
import 'photo_repository.dart';

/// Complete capture-photo persistence used by production.
///
/// The narrower [PhotoRepository] remains available to simple fakes and
/// consumers that only need filed-photo identity.
abstract interface class CapturePhotoRepository implements PhotoRepository {
  /// Writes original [bytes] first, then stores all [photo] metadata.
  Future<Result<PhotoDraft>> saveDraft(PhotoDraft photo, {Uint8List? bytes});
}
