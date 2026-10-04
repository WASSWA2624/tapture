part of 'whisper_library_load.dart';

/// The library opened and passed every check.
final class WhisperLibraryLoaded extends WhisperLibraryLoad {
  /// Wraps the opened [library].
  const WhisperLibraryLoaded(this.library);

  /// The usable library, local to the isolate that opened it.
  final WhisperLibrary library;
}
