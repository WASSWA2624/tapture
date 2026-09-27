/// One entry of a project package, as its manifest lists it.
final class BundleEntry {
  /// Creates an entry.
  const BundleEntry({
    required this.path,
    required this.byteLength,
    required this.sha256,
  });

  /// Reads an entry from its manifest form. Throws [FormatException] when
  /// a field is missing or of the wrong type.
  factory BundleEntry.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('A manifest entry is not an object.');
    }
    final Object? path = json['path'];
    final Object? length = json['byte_length'];
    final Object? sha256 = json['sha256'];
    if (path is! String || length is! int || sha256 is! String) {
      throw const FormatException('A manifest entry is incomplete.');
    }
    return BundleEntry(path: path, byteLength: length, sha256: sha256);
  }

  /// Path inside the package, with forward slashes.
  final String path;

  /// Uncompressed size.
  final int byteLength;

  /// Lower-case hex SHA-256 of the uncompressed bytes.
  final String sha256;

  /// The manifest form.
  Map<String, Object?> toJson() => <String, Object?>{
    'path': path,
    'byte_length': byteLength,
    'sha256': sha256,
  };
}
