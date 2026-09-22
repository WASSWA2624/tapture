import 'package:tapture/core/errors/result.dart';

import 'capture_session.dart';
import 'photo_draft.dart';
import 'photo_repository.dart';

/// Draft-aware photo writes plus interrupted-session persistence.
abstract interface class CapturePersistence {
  /// Underlying photo port.
  PhotoRepository get photos;

  /// Persists [photo] before the session emits.
  Future<Result<PhotoDraft>> savePhoto(PhotoDraft photo);

  /// Tombstones [photoId].
  Future<Result<void>> deletePhoto(String photoId, {required String reason});

  /// Writes the interrupted [session] JSON.
  Future<Result<void>> saveSession(CaptureSession session);

  /// Loads an interrupted session, or null when none.
  Future<Result<CaptureSession?>> loadSession();

  /// Clears interrupted session storage.
  Future<Result<void>> clearSession();
}
