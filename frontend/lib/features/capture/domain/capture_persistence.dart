import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

import 'capture_session.dart';
import 'photo_draft.dart';
import 'photo_repository.dart';

/// Draft-aware photo writes plus interrupted-session persistence.
abstract interface class CapturePersistence {
  /// Underlying photo port.
  PhotoRepository get photos;

  /// Persists [photo] before the session emits.
  Future<Result<PhotoDraft>> savePhoto(PhotoDraft photo, {Uint8List? bytes});

  /// Tombstones [photoId].
  Future<Result<void>> deletePhoto(String photoId, {required String reason});

  /// Writes the interrupted [session] JSON under its
  /// [CaptureSession.storageKey].
  Future<Result<void>> saveSession(CaptureSession session);

  /// Loads the interrupted session stored under [key], or null when none.
  /// [key] is a project id, or `edit:<recordId>` for a record edit (D6).
  Future<Result<CaptureSession?>> loadSession(String key);

  /// Clears the interrupted session stored under [key].
  Future<Result<void>> clearSession(String key);
}
