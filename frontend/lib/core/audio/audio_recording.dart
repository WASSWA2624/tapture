/// Metadata published only after a recorder file has been flushed and hashed.
final class AudioRecording {
  /// Creates completed recording metadata.
  const AudioRecording({
    required this.relativePath,
    required this.sha256,
    required this.byteLength,
    required this.duration,
    required this.mimeType,
  });

  /// Path relative to the storage root.
  final String relativePath;

  /// Content hash.
  final String sha256;

  /// Durable byte count.
  final int byteLength;

  /// Recorded duration.
  final Duration duration;

  /// Encoded media type.
  final String mimeType;
}
