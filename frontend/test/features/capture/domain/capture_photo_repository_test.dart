import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

void main() {
  test(
    'the complete repository accepts original bytes with metadata',
    () async {
      final _CapturePhotos repository = _CapturePhotos();
      const PhotoDraft draft = PhotoDraft(
        id: 'photo-1',
        projectId: 'project-1',
        relativePath: 'photos/photo-1.jpg',
        sha256: '',
      );

      final Result<PhotoDraft> result = await repository.saveDraft(
        draft,
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect((result as Success<PhotoDraft>).value, same(draft));
      expect(repository.bytes, <int>[1, 2, 3]);
    },
  );
}

final class _CapturePhotos implements CapturePhotoRepository {
  List<int>? bytes;

  @override
  Future<Result<PhotoDraft>> saveDraft(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    this.bytes = bytes;
    return Success<PhotoDraft>(photo);
  }

  @override
  Future<Result<PhotoAsset?>> byId(String id) async {
    return const Success<PhotoAsset?>(null);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<PhotoAsset>> save(PhotoAsset photo) async {
    return Success<PhotoAsset>(photo);
  }

  @override
  Stream<List<PhotoAsset>> watchByRecord(String recordId) {
    return Stream<List<PhotoAsset>>.value(const <PhotoAsset>[]);
  }

  @override
  Future<Result<Uint8List>> readBytes(PhotoDraft photo) async {
    return Success<Uint8List>(Uint8List.fromList(bytes ?? const <int>[]));
  }

  @override
  Future<Result<String>> cachedThumbnailPath(
    PhotoDraft photo, {
    required int edge,
  }) async {
    return const Success<String>('thumb');
  }

  @override
  Future<Result<void>> retireDerived(String id) async {
    return const Success<void>(null);
  }
}
