import 'speech_model_kind.dart';
import 'speech_model_tier.dart';

/// One speech model the app knows by its exact bytes and SHA-256.
///
/// Pure Dart, because `tool/speech_models.dart` reads the same entries to
/// fetch and check the bundled files.
final class SpeechModelEntry {
  /// Describes a model; [asset] is null for a model that is only imported.
  const SpeechModelEntry({
    required this.id,
    required this.kind,
    required this.fileName,
    required this.bytes,
    required this.sha256,
    required this.sourceUrl,
    required this.memoryEstimateBytes,
    required this.tier,
    this.asset,
    this.multilingual = true,
    this.nVocab = 0,
    this.nAudioState = 0,
    this.nAudioLayer = 0,
    this.nTextLayer = 0,
    this.nMels = 0,
    this.ftype = -1,
    this.webAllowed = true,
  });

  /// Stable identifier, used in settings, logs and the manifest.
  final String id;

  /// Whether this is a whisper model or a voice-activity model.
  final SpeechModelKind kind;

  /// The upstream file name, kept unchanged on disk.
  final String fileName;

  /// The bundled asset key, or null when the model is import-only.
  final String? asset;

  /// Exact file size in bytes.
  final int bytes;

  /// Exact SHA-256 of the file, as 64 lowercase hex characters.
  final String sha256;

  /// Download URL pinned to a repository commit, never a moving branch.
  final String sourceUrl;

  /// Whether the model transcribes more than English.
  final bool multilingual;

  /// Expected vocabulary size in the header; zero for a VAD model.
  final int nVocab;

  /// Expected audio state width in the header; zero for a VAD model.
  final int nAudioState;

  /// Expected audio layer count in the header; zero for a VAD model.
  final int nAudioLayer;

  /// Expected text layer count in the header; zero for a VAD model.
  final int nTextLayer;

  /// Expected mel band count in the header; zero for a VAD model.
  final int nMels;

  /// Expected weight type, compared as `ftype % 1000`; -1 for a VAD model.
  final int ftype;

  /// Provisional peak memory while loaded, recalibrated by task 128.
  final int memoryEstimateBytes;

  /// The trade this model makes, or null for a VAD model.
  final SpeechModelTier? tier;

  /// Whether the web build may load this model.
  final bool webAllowed;
}
