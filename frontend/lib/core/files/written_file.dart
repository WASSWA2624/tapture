part of 'file_writer.dart';

/// The file this write left on disk, with the hash taken in the same pass.
final class WrittenFile {
  /// Creates a completed write.
  const WrittenFile({
    required this.relativePath,
    required this.sha256,
    required this.byteLength,
  });

  /// Path relative to the storage root, using forward slashes.
  final String relativePath;

  /// SHA-256 of the bytes that landed, hex-encoded.
  final String sha256;

  /// Size of the stored file in bytes.
  final int byteLength;
}
