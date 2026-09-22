import 'dart:convert';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

/// [CapturePersistence] over a [PhotoRepository] and session [TextStore].
final class CapturePersistenceImpl implements CapturePersistence {
  /// Creates persistence over [_photos] and a session [_store].
  CapturePersistenceImpl({required this._photos, required this._store});

  final PhotoRepository _photos;
  final TextStore _store;

  @override
  PhotoRepository get photos => _photos;

  @override
  Future<Result<PhotoDraft>> savePhoto(PhotoDraft photo) async {
    final Result<PhotoAsset> saved = await _photos.save(photo.asAsset);
    return saved.fold(
      FailureResult<PhotoDraft>.new,
      (PhotoAsset asset) => Success<PhotoDraft>(
        photo.copyWith(
          id: asset.id,
          projectId: asset.projectId,
          recordId: asset.recordId,
          relativePath: asset.relativePath,
          sha256: asset.sha256,
        ),
      ),
    );
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) {
    return _photos.delete(photoId, reason: reason);
  }

  @override
  Future<Result<void>> saveSession(CaptureSession session) async {
    try {
      await _store.write(jsonEncode(session.toJson()));
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        StorageFailure(message: error.toString(), recoveryAction: 'Try again.'),
      );
    }
  }

  @override
  Future<Result<CaptureSession?>> loadSession() async {
    try {
      final String? raw = _store.read();
      if (raw == null || raw.isEmpty) {
        return const Success<CaptureSession?>(null);
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const Success<CaptureSession?>(null);
      }
      return Success<CaptureSession?>(
        CaptureSession.fromJson(Map<String, Object?>.from(decoded)),
      );
    } on Object catch (error) {
      return FailureResult<CaptureSession?>(
        StorageFailure(
          message: error.toString(),
          recoveryAction: 'Discard the interrupted session and start again.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> clearSession() async {
    try {
      await _store.write('');
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        StorageFailure(message: error.toString(), recoveryAction: 'Try again.'),
      );
    }
  }
}
