/// The exact bytes a model file must hold. The library sizes and hashes the
/// file before it parses a byte of it, and refuses a mismatch with
/// `WhisperStatus.modelMismatch`.
final class WhisperModelExpectation {
  /// Describes the expected file: its length and its SHA-256 as 64 hex
  /// digits.
  const WhisperModelExpectation({required this.bytes, required this.sha256Hex});

  /// The file's length, in bytes.
  final int bytes;

  /// The file's SHA-256, as 64 hexadecimal digits.
  final String sha256Hex;
}
