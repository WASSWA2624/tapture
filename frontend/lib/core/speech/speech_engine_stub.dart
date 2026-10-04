import 'speech_abort_cell.dart';
import 'speech_engine.dart';
import 'speech_native_api.dart';

/// The engine a platform without on-device speech gets: one that refuses
/// every operation. The native engine (`speech_engine_io.dart`) and the
/// browser engine (task 112) sit behind the same conditional import.
SpeechEngine createSpeechEngine({
  String? libraryPath,
  SpeechNativeApi Function(String? libraryPath)? openApi,
  SpeechAbortCell Function(String? libraryPath)? openAbortCell,
}) => const SpeechEngine.unavailable();
