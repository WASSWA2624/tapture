import 'package:tapture/core/constants/app_constants.dart';

import 'speech_model_entry.dart';

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

  /// The shape a whisper model must report to be [entry]: its catalogue
  /// header facts, with the full encoder context every published whisper
  /// model has.
  factory SpeechModelShape.expectedFor(SpeechModelEntry entry) =>
      SpeechModelShape(
        nVocab: entry.nVocab,
        nAudioCtx: AppConstants.speechEngine.maxAudioContext,
        nAudioState: entry.nAudioState,
        nAudioLayer: entry.nAudioLayer,
        nTextLayer: entry.nTextLayer,
        nMels: entry.nMels,
        ftype: entry.ftype,
        multilingual: entry.multilingual,
      );

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
