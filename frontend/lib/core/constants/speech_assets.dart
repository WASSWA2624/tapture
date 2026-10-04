/// Typed paths for the bundled speech models (FE-STR-12).
///
/// The model files are fetched by hash with `tool/speech_models.dart` and are
/// never committed; only [manifest] is tracked, so a build without models
/// still declares the folder and resolves no model.
abstract final class SpeechAssets {
  /// The asset folder `pubspec.yaml` declares for the speech models.
  static const String folder = 'assets/speech/';

  /// The generated record of every bundled model's bytes and SHA-256.
  static const String manifest = '${folder}manifest.json';

  /// The fast whisper model, quantised tiny.
  static const String tinyModel = '${folder}ggml-tiny-q5_1.bin';

  /// The balanced whisper model, quantised base.
  static const String baseModel = '${folder}ggml-base-q5_1.bin';

  /// The Silero voice-activity model.
  static const String vadModel = '${folder}ggml-silero-v6.2.0.bin';
}
