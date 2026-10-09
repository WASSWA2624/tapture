// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/owned_capture_persistence.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

/// The JSON key the stored sessions sit under.
const String _key = 'sessions';

/// [CapturePersistence] over a [PhotoRepository] and session [TextStore].
///
/// The store holds one JSON object of sessions keyed by storage key, so a
/// record edit sits beside its project's new capture (D6). A store written
/// before keys existed holds a bare session, read under its own key.
final class CapturePersistenceImpl implements OwnedCapturePersistence {
  /// Creates persistence over [_photos] and a session [_store].
  CapturePersistenceImpl({required this._photos, required this._store});

  final PhotoRepository _photos;
  final TextStore _store;
  static final Expando<Future<void>> _mutations = Expando<Future<void>>();

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
  Future<Result<void>> saveSession(CaptureSession session) =>
      _mutate(() => _saveSession(session));

  @override
  Future<Result<void>> saveOwnedSession(
    CaptureSession session, {
    required ({String sessionId, String templateId, int? templateVersion})
    owner,
  }) => _mutate(() => _saveSession(session, owner: owner));

  Future<Result<void>> _saveSession(
    CaptureSession session, {
    ({String sessionId, String templateId, int? templateVersion})? owner,
  }) async {
    try {
      final Map<String, Object?> sessions = _sessions();
      if (owner != null) {
        final Object? stored = sessions[session.storageKey];
        final CaptureSession? current = stored is Map
            ? CaptureSession.fromJson(Map<String, Object?>.from(stored))
            : null;
        if (session.projectId.isEmpty ||
            current == null ||
            current.projectId != session.projectId ||
            current.storageKey != session.storageKey ||
            !_owns(current, owner) ||
            !_owns(session, owner)) {
          return FailureResult<void>(
            StorageFailure(
              localizedMessage: Copy.messages.captureChangeNotSaved,
              localizedRecovery: Copy.messages.captureChangeNotSavedRecovery,
            ),
          );
        }
      }
      sessions[session.storageKey] = session.toJson();
      await _store.write(jsonEncode(<String, Object?>{_key: sessions}));
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        StorageFailure(
          message: error.toString(),
          localizedRecovery: Copy.messages.failureTryAgain,
        ),
      );
    }
  }

  bool _owns(
    CaptureSession session,
    ({String sessionId, String templateId, int? templateVersion}) owner,
  ) =>
      session.id == owner.sessionId &&
      session.templateId == owner.templateId &&
      session.templateVersion == owner.templateVersion;

  Future<Result<void>> _mutate(Future<Result<void>> Function() write) {
    final Future<Result<void>> next =
        (_mutations[_store] ?? Future<void>.value()).then((_) => write());
    _mutations[_store] = next.then<void>((_) {});
    return next;
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
          localizedRecovery:
              Copy.messages.failureDiscardTheInterruptedSessionAndStartAgain,
        ),
      );
    }
  }

  @override
  Future<Result<void>> clearSession(String key) =>
      _mutate(() => _clearSession(key));

  Future<Result<void>> _clearSession(String key) async {
    try {
      final Map<String, Object?> sessions = _sessions()..remove(key);
      await _store.write(
        sessions.isEmpty ? '' : jsonEncode(<String, Object?>{_key: sessions}),
      );
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        StorageFailure(
          message: error.toString(),
          localizedRecovery: Copy.messages.failureTryAgain,
        ),
      );
    }
  }
}
