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

  /// Reads the stored bytes of [photo]. Does not follow a derived parent.
  Future<Result<Uint8List>> readBytes(PhotoDraft photo);

  /// Cached thumbnail path for [photo] at [edge]. Generates the file on a miss.
  Future<Result<String>> cachedThumbnailPath(
    PhotoDraft photo, {
    required int edge,
  });

  /// Builds a thumbnail from [bytes] already held in the capture session.
  Future<Result<String>> cachedThumbnailForBytes(
    PhotoDraft photo,
    Uint8List bytes, {
    required int edge,
  });

  /// Removes a derived row. Refuses an original and never unlinks its file.
  Future<Result<void>> retireDerived(String id);
}
