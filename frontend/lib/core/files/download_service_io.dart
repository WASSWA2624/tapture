import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:tapture/core/errors/result.dart';

import 'download_service.dart';

/// The platform Downloads folder, or the documents folder where a platform
/// has none (iOS).
DownloadService platformDownloads() => folderDownloads(_downloadsFolder);

/// Saves into the folder [folder] resolves to. The seam a suite points at a
/// temporary folder; the app reaches it only through [DownloadService.new].
DownloadService folderDownloads(Future<Directory> Function() folder) {
  return _FolderDownloads(folder);
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
  _FolderDownloads(this._folder);

  final Future<Directory> Function() _folder;

  @override
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final Directory folder = await _folder();
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
