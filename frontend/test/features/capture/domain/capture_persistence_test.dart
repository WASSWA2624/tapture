import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

void main() {
  test(
    'the persistence contract carries bytes and project-scoped recovery',
    () async {
      final _CapturePersistence persistence = _CapturePersistence();
      const PhotoDraft photo = PhotoDraft(
        id: 'photo-1',
        projectId: 'project-1',
        relativePath: 'photos/photo-1.jpg',
        sha256: '',
      );
      const CaptureSession session = CaptureSession(
        id: 'session-1',
        projectId: 'project-1',
        templateId: 'template-1',
        contextSnapshot: <String, String>{},
      );

      await persistence.savePhoto(
        photo,
        bytes: Uint8List.fromList(<int>[1, 2]),
      );
      await persistence.saveSession(session);

      expect(persistence.bytes, <int>[1, 2]);
      expect(
        (await persistence.loadSession('project-1') as Success<CaptureSession?>)
            .value,
        same(session),
      );
      expect(persistence.loadedProjectId, 'project-1');
    },
  );
}

final class _CapturePersistence implements CapturePersistence {
  List<int>? bytes;
  String? loadedProjectId;
  CaptureSession? session;

  @override
  PhotoRepository get photos => throw UnimplementedError();

  @override
  Future<Result<PhotoDraft>> savePhoto(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    this.bytes = bytes;
    return Success<PhotoDraft>(photo);
  }

  @override
  Future<Result<void>> deletePhoto(
    String photoId, {
    required String reason,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> saveSession(CaptureSession session) async {
    this.session = session;
    return const Success<void>(null);
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String projectId) async {
    loadedProjectId = projectId;
    return Success<CaptureSession?>(session);
  }

  @override
  Future<Result<void>> clearSession(String projectId) async {
    session = null;
    return const Success<void>(null);
  }
}
