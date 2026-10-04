part of 'whisper_library_load.dart';

/// The library cannot be used here.
final class WhisperLibraryUnavailable extends WhisperLibraryLoad {
  /// Describes the refusal; [detail] is diagnostic text without any path.
  const WhisperLibraryUnavailable(this.reason, this.detail);

  /// Why the library cannot be used.
  final WhisperUnavailableReason reason;

  /// What exactly failed, for diagnostics.
  final String detail;

  @override
  String toString() => 'WhisperLibraryUnavailable(${reason.name}: $detail)';
}
