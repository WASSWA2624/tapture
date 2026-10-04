import 'dart:io';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Removes [file], a derived application file under [privateRoot]
/// ([StorageRoot.private]), such as a stale extracted speech model or an
/// imported one the operator removes. A missing file is already removed.
///
/// This is the derived-file exemption to FE-SEC-08 (spec §8.1 rule 8): the
/// purge job owns every removal in the evidence tree, and these files are
/// never evidence. A path that is not strictly inside the private root, after
/// `..` segments and links in its folder are resolved, is refused with a
/// [ValidationFailure] and left untouched.
Future<Result<void>> discardDerivedFile(
  File file, {
  required StorageRoot privateRoot,
}) async {
  final Result<Directory> resolved = await privateRoot.resolve();
  switch (resolved) {
    case FailureResult<Directory>(:final Failure failure):
      return FailureResult<void>(failure);
    case Success<Directory>(value: final Directory root):
      return Result.captureAsync<void>(() async {
        if (!await _isInside(file, root)) {
          throw const ValidationFailure();
        }
        if (await file.exists()) {
          await file.delete();
        }
      });
  }
}

/// Whether [file] sits below [root], compared by canonical paths: links and
/// short names are resolved in the deepest folder that exists.
Future<bool> _isInside(File file, Directory root) async {
  final String rootPath = _normalised(await root.resolveSymbolicLinks());
  final List<String> segments = _normalised(file.path).split('/');
  final List<String> missing = <String>[];
  while (segments.length > 1) {
    final Directory folder = Directory(
      segments.sublist(0, segments.length - 1).join('/'),
    );
    if (await folder.exists()) {
      final String resolved = _normalised(await folder.resolveSymbolicLinks());
      final String candidate = <String>[
        resolved,
        ...missing.reversed,
        segments.last,
      ].join('/');
      return candidate.startsWith('$rootPath/');
    }
    missing.add(segments.removeAt(segments.length - 2));
  }
  return false;
}

/// [path] made absolute, with `.` and `..` removed and `/` separators; lower
/// case on Windows, whose file names ignore case.
String _normalised(String path) {
  final bool windows = Platform.isWindows;
  final String absolute = File(path).absolute.path;
  final String plain = Uri.file(
    absolute,
    windows: windows,
  ).normalizePath().toFilePath(windows: windows).replaceAll(r'\', '/');
  final String trimmed = plain.endsWith('/') && plain.length > 1
      ? plain.substring(0, plain.length - 1)
      : plain;
  return windows ? trimmed.toLowerCase() : trimmed;
}
