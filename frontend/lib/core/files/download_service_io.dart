import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

import 'download_service.dart';
import 'external_open_outcome.dart';

export 'external_open_outcome.dart';

/// Native channel that writes into shared `Download/Tapture` on Android 10+.
const MethodChannel _filesChannel = MethodChannel('com.tapture.app/files');

/// Visible folder under Downloads on desktop, and under the app Downloads
/// folder when Android has to fall back.
const String _taptureFolder = 'Tapture';

/// The platform Downloads folder, or the documents folder where a platform
/// has none (iOS).
DownloadService platformDownloads() {
  if (Platform.isAndroid) {
    return androidDownloads();
  }
  if (Platform.isIOS) {
    return folderDownloads(
      _downloadsFolder,
      taptureSubfolder: false,
      checkStorage: true,
      useShare: true,
    );
  }
  return folderDownloads(_downloadsFolder);
}

/// Saves through [channel], then [fallback] when the channel is missing,
/// replies `unsupported`, or throws. The seam a suite drives with a test
/// handler so it never opens MediaStore (FE-STR-11, FE-TEST-03).
DownloadService androidDownloads({
  MethodChannel? channel,
  DownloadService? fallback,
  Future<Directory> Function()? cacheDir,
  Future<ExternalOpenOutcome> Function({
    required String path,
    required String mimeType,
    required String fileName,
  })?
  share,
  PermissionsService? permissions,
}) {
  return _ChannelDownloads(
    channel: channel ?? _filesChannel,
    fallback:
        fallback ??
        folderDownloads(
          _downloadsFolder,
          cacheDir: cacheDir,
          share: share,
          permissions: permissions,
          checkStorage: true,
          useShare: true,
        ),
  );
}

/// Saves into the folder [folder] resolves to. On desktop (and in tests)
/// that is a `Tapture` subfolder. The seam a suite points at a temporary
/// folder; the app reaches it only through [DownloadService.new].
DownloadService folderDownloads(
  Future<Directory> Function() folder, {
  bool taptureSubfolder = true,
  bool? canOpenFolder,
  String? destination,
  Future<void> Function(String executable, List<String> arguments)? open,
  Future<Directory> Function()? cacheDir,
  Future<ExternalOpenOutcome> Function({
    required String path,
    required String mimeType,
    required String fileName,
  })?
  share,
  PermissionsService? permissions,
  bool checkStorage = false,
  bool useShare = false,
}) {
  return _FolderDownloads(
    folder,
    taptureSubfolder: taptureSubfolder,
    canOpenFolder: canOpenFolder ?? taptureSubfolder,
    destination:
        destination ?? (taptureSubfolder ? Copy.downloadsTaptureFolder : null),
    open: open,
    cacheDir: cacheDir,
    share: share,
    permissions: permissions,
    checkStorage: checkStorage,
    useShare: useShare,
  );
}

Future<Directory> _downloadsFolder() async {
  try {
    final Directory? downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }
  } on UnsupportedError {
    // iOS has no Downloads folder; the documents folder is what Files shows.
  }
  return getApplicationDocumentsDirectory();
}

/// Writes through a `.part` file and a rename. An existing file of the same
/// name is never overwritten: the new one is numbered the way a browser
/// numbers a repeated download.
final class _FolderDownloads implements DownloadService {
  _FolderDownloads(
    this._folder, {
    required this._taptureSubfolder,
    required this.canOpenFolder,
    required this.destination,
    required this._open,
    required this._cacheDir,
    required this._share,
    required this._permissions,
    required this._checkStorage,
    required this._useShare,
  });

  final Future<Directory> Function() _folder;
  final bool _taptureSubfolder;
  final Future<void> Function(String executable, List<String> arguments)? _open;
  final Future<Directory> Function()? _cacheDir;
  final Future<ExternalOpenOutcome> Function({
    required String path,
    required String mimeType,
    required String fileName,
  })?
  _share;
  final PermissionsService? _permissions;
  final bool _checkStorage;
  final bool _useShare;

  @override
  final String? destination;

  @override
  final bool canOpenFolder;

  @override
  bool get canChooseLocation => false;

  @override
  bool get canOpenExternally => true;

  @override
  bool get canDownloadCopy => false;

  @override
  Future<Result<String?>> saveAs({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return FailureResult<String?>(downloadFailure(fileName));
  }

  @override
  Future<Result<void>> openFolder() async {
    if (!canOpenFolder) {
      return FailureResult<void>(
        openFolderFailure(destination ?? Copy.downloadsTaptureFolder),
      );
    }
    try {
      final Directory folder = await _targetFolder();
      await folder.create(recursive: true);
      await (_open ?? _runOpen)(_openExecutable, <String>[folder.path]);
      return const Success<void>(null);
    } on Object {
      return FailureResult<void>(
        openFolderFailure(destination ?? Copy.downloadsTaptureFolder),
      );
    }
  }

  @override
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? subfolder,
  }) async {
    try {
      final Directory folder = await _targetFolder(subfolder: subfolder);
      await folder.create(recursive: true);
      final File target = _freeName(folder, fileName);
      final File part = File('${target.path}$_partSuffix');
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(target.path);
      return Success<String?>(target.path);
    } on Object {
      return FailureResult<String?>(downloadFailure(fileName));
    }
  }

  @override
  Future<Result<void>> openExternally({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return _openCopyExternally(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      cacheDir: _cacheDir ?? _defaultCacheDir,
      permissions: _permissions ?? PermissionsService(),
      checkStorage: _checkStorage,
      useShare: _useShare,
      share: _share,
      open: _open,
    );
  }

  Future<Directory> _targetFolder({String? subfolder}) async {
    final Directory base = await _folder();
    if (subfolder == 'Exports') {
      return Directory('${base.path}/$_taptureFolder/Exports');
    }
    return _taptureSubfolder ? Directory('${base.path}/$_taptureFolder') : base;
  }
}

final class _ChannelDownloads implements DownloadService {
  _ChannelDownloads({required this._channel, required this._fallback});

  final MethodChannel _channel;
  final DownloadService _fallback;

  @override
  String? get destination => Copy.downloadsTaptureFolder;

  @override
  bool get canOpenFolder => true;

  @override
  bool get canChooseLocation => true;

  @override
  bool get canOpenExternally => true;

  @override
  bool get canDownloadCopy => false;

  @override
  Future<Result<void>> openExternally({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return _fallback.openExternally(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  @override
  Future<Result<String?>> saveAs({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final Object? name = await _channel.invokeMethod<Object>(
        'saveAs',
        <String, Object>{
          'fileName': fileName,
          'mimeType': mimeType,
          'bytes': bytes,
        },
      );
      if (name is String && name.isNotEmpty) {
        return Success<String?>(name);
      }
      return FailureResult<String?>(downloadFailure(fileName));
    } on PlatformException catch (error) {
      if (error.code == 'cancelled') {
        return const FailureResult<String?>(CancelledFailure());
      }
      return FailureResult<String?>(downloadFailure(fileName));
    } on Object {
      return FailureResult<String?>(downloadFailure(fileName));
    }
  }

  @override
  Future<Result<void>> openFolder() async {
    try {
      await _channel.invokeMethod<void>('openDownloads');
      return const Success<void>(null);
    } on Object {
      return FailureResult<void>(
        openFolderFailure(Copy.downloadsTaptureFolder),
      );
    }
  }

  @override
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? subfolder,
  }) async {
    try {
      final Object? location = await _channel
          .invokeMethod<Object>('saveToDownloads', <String, Object>{
            'fileName': fileName,
            'mimeType': mimeType,
            'bytes': bytes,
            'subfolder': ?subfolder,
          });
      if (location is String && location.isNotEmpty) {
        return Success<String?>(location);
      }
    } on Object {
      // Missing plugin, unsupported API, or any write the channel refused.
    }
    return _fallback.save(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      subfolder: subfolder,
    );
  }
}

File _freeName(Directory folder, String fileName) {
  final int dot = fileName.lastIndexOf('.');
  final String stem = dot <= 0 ? fileName : fileName.substring(0, dot);
  final String extension = dot <= 0 ? '' : fileName.substring(dot);
  File candidate = File('${folder.path}/$fileName');
  int copy = 1;
  while (candidate.existsSync()) {
    copy++;
    candidate = File('${folder.path}/$stem ($copy)$extension');
  }
  return candidate;
}

/// Suffix of an in-flight write. Never the name the file is saved as.
const String _partSuffix = '.part';

String get _openExecutable {
  if (Platform.isWindows) {
    return 'explorer';
  }
  if (Platform.isMacOS) {
    return 'open';
  }
  return 'xdg-open';
}

Future<void> _runOpen(String executable, List<String> arguments) async {
  final ProcessResult result = await Process.run(executable, arguments);
  // explorer.exe returns 1 even when it opened the folder.
  if (executable == 'explorer') {
    return;
  }
  if (result.exitCode != 0) {
    throw ProcessException(executable, arguments);
  }
}

Future<Result<void>> _openCopyExternally({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
  required Future<Directory> Function() cacheDir,
  required PermissionsService permissions,
  required bool checkStorage,
  required bool useShare,
  required Future<ExternalOpenOutcome> Function({
    required String path,
    required String mimeType,
    required String fileName,
  })?
  share,
  required Future<void> Function(String executable, List<String> arguments)?
  open,
}) async {
  File? copy;
  try {
    if (checkStorage) {
      final Result<PermissionState> granted = await permissions.request(
        AppPermission.storage,
      );
      switch (granted) {
        case FailureResult<PermissionState>(:final Failure failure):
          return FailureResult<void>(failure);
        case Success<PermissionState>():
          break;
      }
    }
    final Directory cache = await cacheDir();
    await cache.create(recursive: true);
    copy = File(
      '${cache.path}/open-${DateTime.now().microsecondsSinceEpoch}-'
      '${_safeCopyName(fileName)}',
    );
    await copy.writeAsBytes(bytes, flush: true);
    if (useShare) {
      final ExternalOpenOutcome outcome = await (share ?? _sharePlus)(
        path: copy.path,
        mimeType: mimeType,
        fileName: fileName,
      );
      await _deleteCopy(copy);
      copy = null;
      return switch (outcome) {
        ExternalOpenOutcome.success => const Success<void>(null),
        ExternalOpenOutcome.dismissed => const FailureResult<void>(
          CancelledFailure(),
        ),
        ExternalOpenOutcome.unavailable => FailureResult<void>(
          openExternallyNoHandlerFailure(),
        ),
      };
    }
    await (open ?? _runOpen)(_openExecutable, <String>[copy.path]);
    return const Success<void>(null);
  } on Failure catch (failure) {
    await _deleteCopy(copy);
    return FailureResult<void>(failure);
  } on Object {
    await _deleteCopy(copy);
    return FailureResult<void>(
      useShare
          ? openExternallyFailure(fileName)
          : openExternallyNoHandlerFailure(),
    );
  }
}

Future<ExternalOpenOutcome> _sharePlus({
  required String path,
  required String mimeType,
  required String fileName,
}) async {
  final ShareResult result = await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(path, mimeType: mimeType, name: fileName)],
    ),
  );
  return switch (result.status) {
    ShareResultStatus.success => ExternalOpenOutcome.success,
    ShareResultStatus.dismissed => ExternalOpenOutcome.dismissed,
    ShareResultStatus.unavailable => ExternalOpenOutcome.unavailable,
  };
}

Future<Directory> _defaultCacheDir() async {
  final Result<Directory> cache = await StorageRoot().cacheDir();
  switch (cache) {
    case FailureResult<Directory>(:final Failure failure):
      throw failure;
    case Success<Directory>(:final Directory value):
      return value;
  }
}

String _safeCopyName(String fileName) {
  final String base = fileName.split(RegExp(r'[/\\]')).last;
  return base.isEmpty ? 'file' : base;
}

Future<void> _deleteCopy(File? copy) async {
  if (copy == null) {
    return;
  }
  try {
    if (copy.existsSync()) {
      await copy.delete();
    }
  } on Object {
    // A leftover copy is worse than swallowing a delete error.
  }
}
