import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'file_reader.dart';

/// The reader over the device's file system, under [storageRoot].
FileReader openFileReader({required StorageRoot storageRoot}) {
  return _FileReader(storageRoot);
}

final class _FileReader implements FileReader {
  const _FileReader(this._storageRoot);

  final StorageRoot _storageRoot;

  @override
  Future<Result<Uint8List>> read(String relativePath) async {
    try {
      final String relative = safeRelativePath(relativePath);
      final Result<Directory> root = await _storageRoot.resolve();
      switch (root) {
        case FailureResult<Directory>(:final Failure failure):
          return FailureResult<Uint8List>(failure);
        case Success<Directory>(:final Directory value):
          final File file = File('${value.path}/$relative');
          if (!file.existsSync()) {
            return FailureResult<Uint8List>(FileReader.unreadable(relative));
          }
          return Success<Uint8List>(await file.readAsBytes());
      }
    } on Object {
      return FailureResult<Uint8List>(FileReader.unreadable(relativePath));
    }
  }
}
