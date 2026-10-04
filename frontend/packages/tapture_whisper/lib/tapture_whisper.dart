/// On-device speech-to-text: whisper.cpp 1.9.4 and Silero VAD behind the
/// `tw_*` C ABI v1 (`app-write-up.md` §30.4.1).
///
/// No `dart:ffi` type is public. Open the library with [WhisperLibrary.open];
/// every native refusal arrives as a [WhisperNativeException]. Only
/// `frontend/lib/core/speech/` imports this package (FE-STR-11).
library;

export 'src/whisper_context_options.dart' show WhisperContextOptions;
export 'src/whisper_cpu_facts.dart' show WhisperCpuFacts;
export 'src/whisper_decode_options.dart' show WhisperDecodeOptions;
export 'src/whisper_library.dart'
    show WhisperCell, WhisperLibrary, WhisperModel, WhisperVad;
export 'src/whisper_library_load.dart'
    show WhisperLibraryLoad, WhisperLibraryLoaded, WhisperLibraryUnavailable;
export 'src/whisper_live_objects.dart' show WhisperLiveObjects;
export 'src/whisper_log_level.dart' show WhisperLogLevel;
export 'src/whisper_log_line.dart' show WhisperLogLine;
export 'src/whisper_memory_facts.dart' show WhisperMemoryFacts;
export 'src/whisper_model_expectation.dart' show WhisperModelExpectation;
export 'src/whisper_model_facts.dart' show WhisperModelFacts;
export 'src/whisper_native_exception.dart' show WhisperNativeException;
export 'src/whisper_piece.dart' show WhisperPiece;
export 'src/whisper_segment.dart' show WhisperSegment;
export 'src/whisper_speech_span.dart' show WhisperSpeechSpan;
export 'src/whisper_status.dart' show WhisperStatus;
export 'src/whisper_strategy.dart' show WhisperStrategy;
export 'src/whisper_transcript.dart' show WhisperTranscript;
export 'src/whisper_unavailable_reason.dart' show WhisperUnavailableReason;
export 'src/whisper_vad_options.dart' show WhisperVadOptions;
