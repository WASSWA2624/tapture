/// The hyperparameters of a whisper model as the engine loaded it, compared
/// against the catalogue so a mislabelled file is refused.
final class SpeechModelShape {
  /// Describes a loaded model.
  const SpeechModelShape({
    required this.nVocab,
    required this.nAudioCtx,
    required this.nAudioState,
    required this.nAudioLayer,
    required this.nTextLayer,
    required this.nMels,
    required this.ftype,
    required this.multilingual,
  });

  /// Vocabulary size.
  final int nVocab;

  /// Encoder context in frames.
  final int nAudioCtx;

  /// Encoder state width.
  final int nAudioState;

  /// Encoder layer count.
  final int nAudioLayer;

  /// Decoder layer count.
  final int nTextLayer;

  /// Mel band count.
  final int nMels;

  /// Weight type, as `ftype % 1000`.
  final int ftype;

  /// Whether the model transcribes more than English.
  final bool multilingual;

  @override
  bool operator ==(Object other) =>
      other is SpeechModelShape &&
      other.nVocab == nVocab &&
      other.nAudioCtx == nAudioCtx &&
      other.nAudioState == nAudioState &&
      other.nAudioLayer == nAudioLayer &&
      other.nTextLayer == nTextLayer &&
      other.nMels == nMels &&
      other.ftype == ftype &&
      other.multilingual == multilingual;

  @override
  int get hashCode => Object.hash(
    nVocab,
    nAudioCtx,
    nAudioState,
    nAudioLayer,
    nTextLayer,
    nMels,
    ftype,
    multilingual,
  );
}
