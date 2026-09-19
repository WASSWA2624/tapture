import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';

import 'download_service.dart';

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
    return folderDownloads(_downloadsFolder, taptureSubfolder: false);
  }
  return folderDownloads(_downloadsFolder);
}

/// Saves through [channel], then [fallback] when the channel is missing,
/// replies `unsupported`, or throws. The seam a suite drives with a test
/// handler so it never opens MediaStore (FE-STR-11, FE-TEST-03).
DownloadService androidDownloads({
  MethodChannel? channel,
  DownloadService? fallback,
}) {
  return _ChannelDownloads(
    channel: channel ?? _filesChannel,
    fallback: fallback ?? folderDownloads(_downloadsFolder),
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
}) {
  return _FolderDownloads(
    folder,
    taptureSubfolder: taptureSubfolder,
    canOpenFolder: canOpenFolder ?? taptureSubfolder,
    destination:
        destination ?? (taptureSubfolder ? Copy.downloadsTaptureFolder : null),
    open: open,
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
  });

  final Future<Directory> Function() _folder;
  final bool _taptureSubfolder;
  final Future<void> Function(String executable, List<String> arguments)? _open;

  @override
  final String? destination;

  @override
  final bool canOpenFolder;

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
  }) async {
    try {
      final Directory folder = await _targetFolder();
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

  Future<Directory> _targetFolder() async {
    final Directory base = await _folder();
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
  }) async {
    try {
      final Object? location = await _channel.invokeMethod<Object>(
        'saveToDownloads',
        <String, Object>{
          'fileName': fileName,
          'mimeType': mimeType,
          'bytes': bytes,
        },
      );
      if (location is String && location.isNotEmpty) {
        return Success<String?>(location);
      }
    } on Object {
      // Missing plugin, unsupported API, or any write the channel refused.
    }
    return _fallback.save(fileName: fileName, bytes: bytes, mimeType: mimeType);
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
