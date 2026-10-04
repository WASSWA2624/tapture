import 'speech_engine.dart';

/// The engine a platform without on-device speech gets: one that refuses
/// every operation. Tasks 110 and 112 add the native and browser engines
/// behind the same conditional import.
SpeechEngine createSpeechEngine() => const SpeechEngine.unavailable();
