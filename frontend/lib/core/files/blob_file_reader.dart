import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/path_sanitizer.dart';

import 'file_reader.dart';

/// A [FileReader] over any [BlobStore]: the read side of `BlobFileWriter`,
/// keyed by the same relative path.
final class BlobFileReader implements FileReader {
  /// Reads from [store].
  const BlobFileReader(this._store);

  final BlobStore _store;

  @override
  Future<Result<Uint8List>> read(String relativePath) async {
    final String relative;
    try {
      relative = safeRelativePath(relativePath);
    } on Failure {
      return FailureResult<Uint8List>(FileReader.unreadable(relativePath));
    }
    final Result<Uint8List?> stored = await _store.read(relative);
    return switch (stored) {
      Success<Uint8List?>(:final Uint8List? value) when value != null =>
        Success<Uint8List>(value),
      _ => FailureResult<Uint8List>(FileReader.unreadable(relative)),
    };
  }
}
