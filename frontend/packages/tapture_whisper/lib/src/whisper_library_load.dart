import 'whisper_library.dart';
import 'whisper_unavailable_reason.dart';

part 'whisper_library_loaded.dart';
part 'whisper_library_unavailable.dart';

/// What `WhisperLibrary.open` found: a usable library, or why there is none.
sealed class WhisperLibraryLoad {
  const WhisperLibraryLoad();
}
