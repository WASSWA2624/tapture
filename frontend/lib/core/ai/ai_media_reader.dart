import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Reads AI media through the project store, accepting native service paths.
final class AiMediaReader {
  /// Uses [files] for all bytes; absolute native paths must stay under [storageRoot].
  const AiMediaReader({
    required this._files,
    required this._storageRoot,
    this._isBrowser = kIsWeb,
  });

  final FileReader _files;
  final StorageRoot _storageRoot;
  final bool _isBrowser;

  /// Returns local media without allowing paths outside the project storage root.
  Future<Result<Uint8List>> read(String path) async {
    if (_isBrowser || !_absolute.hasMatch(path)) return _files.read(path);
    final Result<Directory> root = await _storageRoot.resolve();
    if (root case FailureResult<Directory>(:final Failure failure)) {
      return FailureResult<Uint8List>(failure);
    }
    final String prefix =
        '${(root as Success<Directory>).value.absolute.path.replaceAll(r'\', '/')}/';
    final String normalized = path.replaceAll(r'\', '/');
    final bool inside = Platform.isWindows
        ? normalized.toLowerCase().startsWith(prefix.toLowerCase())
        : normalized.startsWith(prefix);
    if (!inside) return FailureResult<Uint8List>(FileReader.unreadable(path));
    return _files.read(normalized.substring(prefix.length));
  }
}

final RegExp _absolute = RegExp(r'^(?:[A-Za-z]:[/\\]|[/\\])');
