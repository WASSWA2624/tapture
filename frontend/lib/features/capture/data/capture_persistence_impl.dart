// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

/// The JSON key the stored sessions sit under.
const String _key = 'sessions';

/// [CapturePersistence] over a [PhotoRepository] and session [TextStore].
///
/// The store holds one JSON object of sessions keyed by storage key, so a
/// record edit sits beside its project's new capture (D6). A store written
/// before keys existed holds a bare session, read under its own key.
final class CapturePersistenceImpl implements CapturePersistence {
  /// Creates persistence over [_photos] and a session [_store].
  CapturePersistenceImpl({required this._photos, required this._store});

  final PhotoRepository _photos;
  final TextStore _store;

  @override
  PhotoRepository get photos => _photos;

  /// The stored sessions by key. Throws when the stored JSON cannot be read.
  Map<String, Object?> _sessions() {
    final String? raw = _store.read();
    if (raw == null || raw.isEmpty) {
      return <String, Object?>{};
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return <String, Object?>{};
    }
    final Object? keyed = decoded[_key];
    if (keyed is Map) {
      return Map<String, Object?>.from(keyed);
    }
    // A bare session from before keys, stored under its own key.
    final CaptureSession legacy = CaptureSession.fromJson(
      Map<String, Object?>.from(decoded),
    );
    return <String, Object?>{legacy.storageKey: legacy.toJson()};
  }

  @override
  Future<Result<PhotoDraft>> savePhoto(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    if (_photos case final CapturePhotoRepository complete) {
      return complete.saveDraft(photo, bytes: bytes);
    }
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
      final Map<String, Object?> sessions = _sessions()
        ..[session.storageKey] = session.toJson();
      await _store.write(jsonEncode(<String, Object?>{_key: sessions}));
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        StorageFailure(message: error.toString(), recoveryAction: 'Try again.'),
      );
    }
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String key) async {
    try {
      final Object? stored = _sessions()[key];
      if (stored is! Map) {
        return const Success<CaptureSession?>(null);
      }
      return Success<CaptureSession?>(
        CaptureSession.fromJson(Map<String, Object?>.from(stored)),
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
  Future<Result<void>> clearSession(String key) async {
    try {
      final Map<String, Object?> sessions = _sessions()..remove(key);
      await _store.write(
        sessions.isEmpty ? '' : jsonEncode(<String, Object?>{_key: sessions}),
      );
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        StorageFailure(message: error.toString(), recoveryAction: 'Try again.'),
      );
    }
  }
}
