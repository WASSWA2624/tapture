part of 'orphan_scanner.dart';

/// A file on disk that no photo or attachment row points at.
final class OrphanFile {
  /// Creates an orphan. [path] is relative to the project folder.
  const OrphanFile({
    required this.path,
    required this.bytes,
    required this.kind,
  });

  /// Project-relative path, using forward slashes.
  final String path;

  /// Size of the file in bytes.
  final int bytes;

  /// Detected kind: `photo`, `document`, `audio` or `other`.
  final String kind;
}
