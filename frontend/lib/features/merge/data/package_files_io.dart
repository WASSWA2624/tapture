import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'package_files.dart';

/// On a device the files go under the storage root through [FileWriter]'s
/// atomic write.
PackageFiles openPackageFiles({
  required StorageRoot storageRoot,
  FileWriter? writer,
}) {
  return _DevicePackageFiles(
    storageRoot,
    writer ?? FileWriter(storageRoot: storageRoot),
  );
}

final class _DevicePackageFiles implements PackageFiles {
  _DevicePackageFiles(this._root, this._writer);

  final StorageRoot _root;
  final FileWriter _writer;

  @override
  Future<Result<WrittenFile>> write(String relativePath, Uint8List bytes) {
    return writeStream(relativePath, Stream<List<int>>.value(bytes));
  }

  @override
  Future<Result<WrittenFile>> writeStream(
    String relativePath,
    Stream<List<int>> bytes,
  ) => writePackageFileStream(_writer, relativePath, bytes);

  @override
  Future<Result<Uint8List>> read(String relativePath) {
    return FileReader(storageRoot: _root).read(relativePath);
  }

  @override
  Future<void> move(String source, String target) async {
    final String? from = await _resolve(source);
    final String? to = await _resolve(target);
    if (from == null || to == null) {
      final StorageFailure pathFailure = FileReader.unreadable(source);
      throw pathFailure;
    }
    final File destination = File(to);
    if (await destination.exists()) {
      final StorageFailure pathFailure = FileReader.unreadable(target);
      throw pathFailure;
    }
    await destination.parent.create(recursive: true);
    await File(from).rename(to);
  }

  @override
  Future<bool> exists(String relativePath) async {
    final String? path = await _resolve(relativePath);
    return path != null &&
        await FileSystemEntity.type(path) != FileSystemEntityType.notFound;
  }

  @override
  Future<void> remove(String relativePath) async {
    final String? path = await _resolve(relativePath);
    if (path == null) {
      return;
    }
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> removeFolder(String relativePath) async {
    final String? path = await _resolve(relativePath);
    if (path == null) {
      return;
    }
    final Directory folder = Directory(path);
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  /// The absolute path of [relativePath], or null when it would leave the
  /// storage root or the root cannot be opened.
  Future<String?> _resolve(String relativePath) async {
    final String relative;
    try {
      relative = safeRelativePath(relativePath);
    } on Failure {
      return null;
    }
    final Result<Directory> root = await _root.resolve();
    return switch (root) {
      Success<Directory>(:final Directory value) =>
        '${value.path}${Platform.pathSeparator}'
            '${relative.replaceAll('/', Platform.pathSeparator)}',
      FailureResult<Directory>() => null,
    };
  }
}
