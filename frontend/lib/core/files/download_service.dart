import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'download_service_stub.dart'
    if (dart.library.io) 'download_service_io.dart'
    if (dart.library.js_interop) 'download_service_web.dart'
    as platform;

/// Hands a finished file to the person: a browser download on the web,
/// shared `Download/Tapture` on Android 10+, `Downloads/Tapture` on
/// desktop, and the documents folder on iOS. The only way a feature saves
/// a file for someone to open elsewhere (FE-STR-11).
abstract interface class DownloadService {
  /// The service for this platform.
  factory DownloadService() => platform.platformDownloads();

  /// A stand-in that reports each save to [onSave] instead of writing, so
  /// tests never touch a folder or a browser (FE-TEST-03). [fail] makes every
  /// save return a storage failure.
  factory DownloadService.fake({
    void Function(String fileName, Uint8List bytes, String mimeType)? onSave,
    bool fail = false,
  }) {
    return _FakeDownloadService(onSave: onSave, fail: fail);
  }

  /// Saves [bytes] as [fileName]. Succeeds with where the file went, which
  /// is null when the browser decides. On Android 10+ that is
  /// `Download/Tapture/<name>`; on desktop, the path under
  /// `Downloads/Tapture/`.
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

final class _FakeDownloadService implements DownloadService {
  _FakeDownloadService({required this._onSave, required this._fail});

  final void Function(String fileName, Uint8List bytes, String mimeType)?
  _onSave;
  final bool _fail;

  @override
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (_fail) {
      return FailureResult<String?>(downloadFailure(fileName));
    }
    _onSave?.call(fileName, bytes, mimeType);
    return Success<String?>('downloads/$fileName');
  }
}

/// The failure any platform returns when the file could not be saved.
StorageFailure downloadFailure(String fileName) {
  return StorageFailure(
    message: 'Tapture could not save $fileName.',
    recoveryAction: 'Free some space, then download again.',
  );
}
