/// The hyperparameters of a loaded whisper model (`tw_model_facts`).
final class WhisperModelFacts {
  /// Describes a loaded model.
  const WhisperModelFacts({
    required this.nVocab,
    required this.nAudioCtx,
    required this.nAudioState,
    required this.nAudioHead,
    required this.nAudioLayer,
    required this.nTextCtx,
    required this.nTextState,
    required this.nTextHead,
    required this.nTextLayer,
    required this.nMels,
    required this.ftype,
    required this.modelType,
    required this.multilingual,
  });

  /// Vocabulary size.
  final int nVocab;

  /// Encoder context, in frames.
  final int nAudioCtx;

  /// Encoder state width.
  final int nAudioState;

  /// Encoder attention heads.
  final int nAudioHead;

  /// Encoder layers.
  final int nAudioLayer;

  /// Decoder context, in pieces.
  final int nTextCtx;

  /// Decoder state width.
  final int nTextState;

  /// Decoder attention heads.
  final int nTextHead;

  /// Decoder layers.
  final int nTextLayer;

  /// Mel bands.
  final int nMels;

  /// whisper's weight type; 9 is Q5_1.
  final int ftype;

  /// 0 unknown, 1 tiny, 2 base, 3 small, 4 medium, 5 large.
  final int modelType;

  /// Whether the model transcribes more than English.
  final bool multilingual;
}
