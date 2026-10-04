import 'whisper_strategy.dart';

/// How one transcription decodes (`tw_transcribe_options`). Every default
/// equals `tw_transcribe_options_init`; the language has no default, because
/// the library never detects one.
final class WhisperDecodeOptions {
  /// Describes the options.
  ///
  /// Throws an [ArgumentError] when [language] is empty, is `auto`, is not
  /// ASCII or is longer than seven characters: an empty or `auto` language
  /// would start whisper's separate detection pass, which no abort reaches.
  /// Whether a well-formed code is one whisper knows is checked by the
  /// library, which refuses an unknown one with
  /// `WhisperStatus.invalidArgument`.
  WhisperDecodeOptions({
    required this.language,
    this.strategy = WhisperStrategy.greedy,
    this.threads = 0,
    this.bestOf = 5,
    this.beamSize = 5,
    this.maxPieces = 0,
    this.audioContext = 0,
    this.maxTextContext = 16384,
    this.temperature = 0,
    this.temperatureIncrement = 0.2,
    this.entropyThreshold = 2.4,
    this.logProbabilityThreshold = -1,
    this.noSpeechThreshold = 0.6,
    this.lengthPenalty = -1,
    this.maxInitialTimestamp = 1,
    this.pieceProbabilityThreshold = 0.01,
    this.pieceProbabilitySumThreshold = 0.01,
    this.translate = false,
    this.noContext = true,
    this.singleSegment = false,
    this.noTimestamps = false,
    this.pieceTimestamps = false,
    this.suppressBlank = true,
    this.suppressNonSpeech = true,
    this.carryInitialPrompt = false,
  }) {
    if (language.isEmpty ||
        language.toLowerCase() == 'auto' ||
        language.length > maxLanguageLength ||
        language.codeUnits.any((int unit) => unit < 0x21 || unit > 0x7e)) {
      throw ArgumentError.value(
        language,
        'language',
        'a whisper language code: never empty or auto, at most '
            '$maxLanguageLength ASCII characters',
      );
    }
  }

  /// The longest language code the native struct holds, without its NUL.
  static const int maxLanguageLength = 7;

  /// The spoken language, as whisper's code (`en`, `fr`, …). An English-only
  /// model always decodes English.
  final String language;

  /// Greedy decoding or beam search.
  final WhisperStrategy strategy;

  /// Compute threads for this call; 0 uses the model's.
  final int threads;

  /// Greedy candidates on a temperature fallback, 1..8.
  final int bestOf;

  /// Beams of a beam search, 1..8.
  final int beamSize;

  /// Most pieces per segment; 0 is unlimited.
  final int maxPieces;

  /// Encoder frames to use; 0 is the model's, otherwise 64..`nAudioCtx`.
  final int audioContext;

  /// Most prompt pieces kept as context; above 0 whenever a prompt is given.
  final int maxTextContext;

  /// The first sampling temperature.
  final double temperature;

  /// The temperature step of the fallback; 0 disables it.
  final double temperatureIncrement;

  /// Entropy above which a decode falls back.
  final double entropyThreshold;

  /// Average log probability below which a decode falls back.
  final double logProbabilityThreshold;

  /// No-speech probability above which a silent window is skipped.
  final double noSpeechThreshold;

  /// Beam length penalty; -1 is whisper's simple length normalisation.
  final double lengthPenalty;

  /// The latest initial timestamp, in seconds.
  final double maxInitialTimestamp;

  /// The probability a timestamp piece needs.
  final double pieceProbabilityThreshold;

  /// The probability sum a timestamp piece needs.
  final double pieceProbabilitySumThreshold;

  /// Whether to translate into English instead of transcribing.
  final bool translate;

  /// Whether to ignore earlier text as context.
  final bool noContext;

  /// Whether to force one segment.
  final bool singleSegment;

  /// Whether to decode without timestamps.
  final bool noTimestamps;

  /// Whether to time every piece.
  final bool pieceTimestamps;

  /// Whether to suppress a blank first piece.
  final bool suppressBlank;

  /// Whether to suppress non-speech pieces.
  final bool suppressNonSpeech;

  /// Whether the initial prompt is kept across windows.
  final bool carryInitialPrompt;
}
