import 'whisper_status.dart';

/// A native call that did not succeed. Every refusal of the library, and every
/// argument this package refuses before calling it, arrives as this exception.
final class WhisperNativeException implements Exception {
  /// Describes a failed call; [whisperCode] is whisper.cpp's own return code
  /// when [status] is [WhisperStatus.inference] or [WhisperStatus.poisoned].
  const WhisperNativeException(this.status, {this.whisperCode = 0});

  /// What the library reported.
  final WhisperStatus status;

  /// whisper.cpp's return code of the failed transcription, or 0.
  final int whisperCode;

  @override
  String toString() =>
      'WhisperNativeException(${status.name}, whisperCode: $whisperCode)';
}
