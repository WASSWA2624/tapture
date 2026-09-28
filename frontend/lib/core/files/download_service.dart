import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/path_sanitizer.dart';

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
  /// save return a storage failure. [destination], [canOpenFolder] and
  /// [onOpenFolder] stand in for the location line and Open folder.
  /// [canChooseLocation], [onSaveAs] and [saveAsCancel] stand in for Save
  /// to a folder. [canOpenExternally], [canDownloadCopy] and
  /// [onOpenExternally] stand in for Open with, and [canShareToApps] for a
  /// platform share sheet. [onSaveStored] and [onOpenStoredExternally]
  /// report the stored-file calls. The fake never writes a file, and takes a
  /// stored path only from a project's exports folder (FE-TEST-03,
  /// FE-SEC-08).
  factory DownloadService.fake({
    void Function(String fileName, Uint8List bytes, String mimeType)? onSave,
    bool fail = false,
    String? destination,
    bool canOpenFolder = false,
    bool openFolderFail = false,
    void Function()? onOpenFolder,
    bool canChooseLocation = false,
    bool saveAsCancel = false,
    void Function(String fileName, Uint8List bytes, String mimeType)? onSaveAs,
    bool canOpenExternally = false,
    bool canDownloadCopy = false,
    bool canShareToApps = false,
    bool openCancel = false,
    bool openNoHandler = false,
    bool openPermissionDenied = false,
    void Function(String fileName, Uint8List bytes, String mimeType)?
    onOpenExternally,
    void Function(String relativePath, String fileName, String mimeType)?
    onSaveStored,
    void Function(String relativePath, String fileName, String mimeType)?
    onOpenStoredExternally,
  }) {
    return _FakeDownloadService(
      onSave: onSave,
      fail: fail,
      destination: destination,
      canOpenFolder: canOpenFolder,
      openFolderFail: openFolderFail,
      onOpenFolder: onOpenFolder,
      canChooseLocation: canChooseLocation,
      saveAsCancel: saveAsCancel,
      onSaveAs: onSaveAs,
      canOpenExternally: canOpenExternally,
      canDownloadCopy: canDownloadCopy,
      canShareToApps: canShareToApps,
      openCancel: openCancel,
      openNoHandler: openNoHandler,
      openPermissionDenied: openPermissionDenied,
      onOpenExternally: onOpenExternally,
      onSaveStored: onSaveStored,
      onOpenStoredExternally: onOpenStoredExternally,
    );
  }

  /// Short label for where archives land, or null where the browser
  /// decides.
  String? get destination;

  /// Whether [openFolder] can take the operator to that place.
  bool get canOpenFolder;

  /// Opens the downloads folder, or the system Downloads view on Android.
  Future<Result<void>> openFolder();

  /// Whether [saveAs] can offer the system save picker.
  bool get canChooseLocation;

  /// Saves [bytes] through the system picker as [fileName]. Succeeds with
  /// the display name the picker kept, or [CancelledFailure] when the
  /// picker is dismissed.
  Future<Result<String?>> saveAs({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });

  /// Saves [bytes] as [fileName]. Succeeds with where the file went, which
  /// is null when the browser decides. On Android 10+ that is
  /// `Download/Tapture/<name>`; on desktop, the path under
  /// `Downloads/Tapture/`. [subfolder] is a single extra folder under
  /// Tapture, used by project exports. Null keeps the shared Tapture folder.
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? subfolder,
  });

  /// Whether [openExternally] can hand a copy to another app.
  bool get canOpenExternally;

  /// Whether the platform can save a copy instead of opening one. The web
  /// uses this so the menu still offers a way out of the app.
  bool get canDownloadCopy;

  /// Whether [openExternally] opens the system share sheet, which lists
  /// every installed app that takes the file (Android and iOS).
  bool get canShareToApps;

  /// Hands a copy of [bytes] named [fileName] to another app, or saves it
  /// where the platform cannot open one. Never takes a stored path outside
  /// a project's exports folder: those go through [openStoredExternally].
  Future<Result<void>> openExternally({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });

  /// Saves the stored file at [relativePath] (under the storage root) as
  /// [fileName], copying it in chunks so a package larger than memory is
  /// never read whole (FE-PERF-07). Only a file in a project's `exports/`
  /// folder is accepted ([isStoredExport]), so no original photo or
  /// recording is ever handed out (FE-SEC-08). A browser has no stored files
  /// and refuses.
  Future<Result<String?>> saveStored({
    required String relativePath,
    required String fileName,
    required String mimeType,
    String? subfolder,
  });

  /// Hands the stored file at [relativePath] to another app, under the same
  /// rule as [saveStored].
  Future<Result<void>> openStoredExternally({
    required String relativePath,
    required String fileName,
    required String mimeType,
  });
}

/// Whether [relativePath] names a file in a project's exports folder,
/// `projects/<folder>/exports/<file>` or a deliverable under
/// `projects/<folder>/exports/<date>/<id>/<file>`: the only stored files a
/// [DownloadService] hands out. A folder path is never a file.
bool isStoredExport(String relativePath) {
  final String safe;
  try {
    safe = safeRelativePath(relativePath);
  } on Object {
    return false;
  }
  final List<String> parts = safe.split('/');
  return parts.length >= 4 &&
      parts[0] == 'projects' &&
      parts[2] == 'exports' &&
      parts.every((String part) => part.isNotEmpty);
}

/// Where a file is handed to the operator. Tests keep the fake.
final Provider<DownloadService> downloadServiceProvider =
    Provider<DownloadService>((Ref _) {
      return DownloadService.fake();
    });

final class _FakeDownloadService implements DownloadService {
  _FakeDownloadService({
    required this._onSave,
    required this._fail,
    required this.destination,
    required this.canOpenFolder,
    required this._openFolderFail,
    required this._onOpenFolder,
    required this.canChooseLocation,
    required this._saveAsCancel,
    required this._onSaveAs,
    required this.canOpenExternally,
    required this.canDownloadCopy,
    required this.canShareToApps,
    required this._openCancel,
    required this._openNoHandler,
    required this._openPermissionDenied,
    required this._onOpenExternally,
    required this._onSaveStored,
    required this._onOpenStoredExternally,
  });

  final void Function(String fileName, Uint8List bytes, String mimeType)?
  _onSave;
  final bool _fail;
  final bool _openFolderFail;
  final void Function()? _onOpenFolder;
  final bool _saveAsCancel;
  final void Function(String fileName, Uint8List bytes, String mimeType)?
  _onSaveAs;
  final bool _openCancel;
  final bool _openNoHandler;
  final bool _openPermissionDenied;
  final void Function(String fileName, Uint8List bytes, String mimeType)?
  _onOpenExternally;
  final void Function(String relativePath, String fileName, String mimeType)?
  _onSaveStored;
  final void Function(String relativePath, String fileName, String mimeType)?
  _onOpenStoredExternally;

  @override
  final String? destination;

  @override
  final bool canOpenFolder;

  @override
  final bool canChooseLocation;

  @override
  final bool canOpenExternally;

  @override
  final bool canDownloadCopy;

  @override
  final bool canShareToApps;

  @override
  Future<Result<void>> openFolder() async {
    _onOpenFolder?.call();
    if (_openFolderFail || !canOpenFolder) {
      return FailureResult<void>(
        openFolderFailure(destination ?? Copy.downloadsTaptureFolder),
      );
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<String?>> saveAs({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    _onSaveAs?.call(fileName, bytes, mimeType);
    if (_saveAsCancel) {
      return const FailureResult<String?>(CancelledFailure());
    }
    if (_fail || !canChooseLocation) {
      return FailureResult<String?>(downloadFailure(fileName));
    }
    return Success<String?>(fileName);
  }

  @override
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? subfolder,
  }) async {
    if (_fail) {
      return FailureResult<String?>(downloadFailure(fileName));
    }
    _onSave?.call(fileName, bytes, mimeType);
    final String place = subfolder == null
        ? 'downloads/$fileName'
        : 'downloads/$subfolder/$fileName';
    return Success<String?>(place);
  }

  @override
  Future<Result<void>> openExternally({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    _onOpenExternally?.call(fileName, bytes, mimeType);
    if (_openPermissionDenied) {
      return const FailureResult<void>(
        PermissionFailure(
          message: Copy.projectOpenPermission,
          recoveryAction: Copy.projectOpenPermissionRecovery,
        ),
      );
    }
    if (_openCancel) {
      return const FailureResult<void>(CancelledFailure());
    }
    if (_openNoHandler) {
      return FailureResult<void>(openExternallyNoHandlerFailure());
    }
    if (_fail || (!canOpenExternally && !canDownloadCopy)) {
      return FailureResult<void>(openExternallyFailure(fileName));
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<String?>> saveStored({
    required String relativePath,
    required String fileName,
    required String mimeType,
    String? subfolder,
  }) async {
    if (_fail || !isStoredExport(relativePath)) {
      return FailureResult<String?>(downloadFailure(fileName));
    }
    _onSaveStored?.call(relativePath, fileName, mimeType);
    final String place = subfolder == null
        ? 'downloads/$fileName'
        : 'downloads/$subfolder/$fileName';
    return Success<String?>(place);
  }

  @override
  Future<Result<void>> openStoredExternally({
    required String relativePath,
    required String fileName,
    required String mimeType,
  }) async {
    if (!isStoredExport(relativePath)) {
      return FailureResult<void>(openExternallyFailure(fileName));
    }
    _onOpenStoredExternally?.call(relativePath, fileName, mimeType);
    if (_openPermissionDenied) {
      return const FailureResult<void>(
        PermissionFailure(
          message: Copy.projectOpenPermission,
          recoveryAction: Copy.projectOpenPermissionRecovery,
        ),
      );
    }
    if (_openCancel) {
      return const FailureResult<void>(CancelledFailure());
    }
    if (_openNoHandler) {
      return FailureResult<void>(openExternallyNoHandlerFailure());
    }
    if (_fail || (!canOpenExternally && !canDownloadCopy)) {
      return FailureResult<void>(openExternallyFailure(fileName));
    }
    return const Success<void>(null);
  }
}

/// The failure any platform returns when the file could not be saved.
StorageFailure downloadFailure(String fileName) {
  return StorageFailure(
    message: 'Tapture could not save $fileName.',
    recoveryAction: 'Free some space, then download again.',
  );
}

/// The failure any platform returns when the downloads folder could not be
/// opened. [place] is the short label the operator should look in.
StorageFailure openFolderFailure(String place) {
  return StorageFailure(
    message: Copy.feedbackOpenFolderFailed(place),
    recoveryAction: 'Open Downloads on this device and look in Tapture.',
  );
}

/// The failure any platform returns when a copy could not be handed off.
StorageFailure openExternallyFailure(String fileName) {
  return StorageFailure(
    message: Copy.projectOpenFailedNamed(fileName),
    recoveryAction: Copy.projectOpenFailedRecovery,
  );
}

/// The failure when no installed app can open the copy.
StorageFailure openExternallyNoHandlerFailure() {
  return const StorageFailure(
    message: Copy.projectOpenNoApp,
    recoveryAction: Copy.projectOpenNoAppRecovery,
  );
}
