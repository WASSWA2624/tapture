import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

/// An in-memory [CapturePhotoRepository]: drafts and their bytes are kept by
/// id, a delete tombstones and keeps both (so a discard stays recoverable),
/// and each photo's cached thumbnail is a real file under [thumbs], so
/// `AppPhotoThumb` draws it (FE-TEST-03).
final class FakeCapturePhotoRepository implements CapturePhotoRepository {
  @override
  Stream<List<DeletedEntity>> watchDeleted() => Stream<List<DeletedEntity>>.value(<DeletedEntity>[
    for (final PhotoDraft draft in drafts.values)
      if (tombstoned.contains(draft.id)) DeletedEntity(id: draft.id, kind: DeletedEntityKind.photo,
        name: draft.originalFilename, projectId: draft.projectId, projectName: draft.projectId, deletedAt: DateTime.utc(2026)),
  ]);

  @override
  Future<Result<void>> restore(String id) async {
    if (!drafts.containsKey(id)) return const FailureResult<void>(_unreadable);
    tombstoned.remove(id);
    return const Success<void>(null);
  }

  /// Creates the fake. Thumbnails are written under [thumbs].
  FakeCapturePhotoRepository({required this.thumbs});

  /// Where cached thumbnails are written.
  final Directory thumbs;

  /// Every draft saved, by id, as last written.
  final Map<String, PhotoDraft> drafts = <String, PhotoDraft>{};

  /// The bytes written with each draft, by id.
  final Map<String, Uint8List> bytes = <String, Uint8List>{};

  /// Ids deleted and not saved again: tombstoned, their rows and bytes kept.
  final Set<String> tombstoned = <String>{};

  /// When set, [saveDraft] returns this and writes nothing.
  Failure? saveFailure;

  /// The cached thumbnail file of [photoId].
  String thumbPathFor(String photoId) => '${thumbs.path}/thumb-$photoId.png';

  @override
  Future<Result<PhotoDraft>> saveDraft(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    final Failure? refused = saveFailure;
    if (refused != null) {
      return FailureResult<PhotoDraft>(refused);
    }
    drafts[photo.id] = photo;
    if (bytes != null) {
      this.bytes[photo.id] = bytes;
    }
    tombstoned.remove(photo.id);
    return Success<PhotoDraft>(photo);
  }

  @override
  Future<Result<PhotoAsset?>> byId(String id) async {
    return Success<PhotoAsset?>(drafts[id]?.asAsset);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    tombstoned.add(id);
    return const Success<void>(null);
  }

  @override
  Future<Result<PhotoAsset>> save(PhotoAsset photo) async {
    return Success<PhotoAsset>(photo);
  }

  @override
  Stream<List<PhotoAsset>> watchByRecord(String recordId) {
    return Stream<List<PhotoAsset>>.value(<PhotoAsset>[
      for (final PhotoDraft draft in drafts.values)
        if (draft.recordId == recordId && !tombstoned.contains(draft.id))
          draft.asAsset,
    ]);
  }

  @override
  Future<Result<Uint8List>> readBytes(PhotoDraft photo) async {
    final Uint8List? stored = bytes[photo.id];
    if (stored == null) {
      return const FailureResult<Uint8List>(_unreadable);
    }
    return Success<Uint8List>(stored);
  }

  @override
  Future<Result<String>> cachedThumbnailPath(
    PhotoDraft photo, {
    required int edge,
  }) async {
    return Success<String>(_thumb(photo.id));
  }

  @override
  Future<Result<String>> cachedThumbnailForBytes(
    PhotoDraft photo,
    Uint8List bytes, {
    required int edge,
  }) async {
    return Success<String>(_thumb(photo.id));
  }

  @override
  Future<Result<void>> retireDerived(String id) async {
    tombstoned.add(id);
    return const Success<void>(null);
  }

  String _thumb(String photoId) {
    final File file = File(thumbPathFor(photoId));
    if (!file.existsSync()) {
      file
        ..createSync(recursive: true)
        ..writeAsBytesSync(_onePixelPng);
    }
    return file.path;
  }
}

const StorageFailure _unreadable = StorageFailure(
  message: 'That photo could not be read from this device.',
  recoveryAction: 'Capture the photo again, then try again.',
);

/// A valid 1×1 PNG, so the thumbnail decodes like a real one.
final Uint8List _onePixelPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);
