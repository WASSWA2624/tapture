import 'package:tapture/core/constants/speech_assets.dart';

import 'speech_model_entry.dart';
import 'speech_model_kind.dart';
import 'speech_model_tier.dart';

/// Hugging Face repository commits, resolved once (task 101) so a moved
/// branch can never change what a pinned URL serves.
const String _whisperSource =
    'https://huggingface.co/ggerganov/whisper.cpp/resolve/'
    '5359861c739e955e79d9a303bcbc70fb988958b1';
const String _vadSource =
    'https://huggingface.co/ggml-org/whisper-vad/resolve/'
    '9ffd54a1e1ee413ddf265af9913beaf518d1639b';

const int _mebibyte = 1024 * 1024;

/// Header facts every multilingual whisper model shares.
const int _whisperVocab = 51865;
const int _whisperMels = 80;

/// `ftype % 1000` of a q5_1 quantised whisper model.
const int _q5Ftype = 9;

/// Every speech model the app accepts, at its exact bytes and SHA-256.
///
/// The single source of truth for the model files: `tool/speech_models.dart`
/// fetches and checks the bundled entries and generates
/// `assets/speech/manifest.json` from them. Header facts are pinned by the
/// native shape tests. Memory estimates are the peak RSS a loaded model adds
/// while it decodes jfk with the desktop committed profile, worker isolates
/// included, measured on the Windows reference machine by
/// `speech_engine_benchmark_test` (task 128, 2026-10-05), rounded up to
/// 8 MiB (1 MiB for the voice detector): tiny 126.4, base 166.2, small
/// 349.7 and Silero 8.3 MiB.
abstract final class SpeechModelCatalogue {
  /// The bundled fast model.
  static const SpeechModelEntry tiny = SpeechModelEntry(
    id: 'tiny-q5_1',
    kind: SpeechModelKind.whisper,
    fileName: 'ggml-tiny-q5_1.bin',
    asset: SpeechAssets.tinyModel,
    bytes: 32152673,
    sha256: '818710568da3ca15689e31a743197b520007872ff9576237bda97bd1b469c3d7',
    sourceUrl: '$_whisperSource/ggml-tiny-q5_1.bin',
    nVocab: _whisperVocab,
    nAudioState: 384,
    nAudioLayer: 4,
    nTextLayer: 4,
    nMels: _whisperMels,
    ftype: _q5Ftype,
    memoryEstimateBytes: 128 * _mebibyte,
    tier: SpeechModelTier.fast,
  );

  /// The bundled balanced model.
  static const SpeechModelEntry base = SpeechModelEntry(
    id: 'base-q5_1',
    kind: SpeechModelKind.whisper,
    fileName: 'ggml-base-q5_1.bin',
    asset: SpeechAssets.baseModel,
    bytes: 59707625,
    sha256: '422f1ae452ade6f30a004d7e5c6a43195e4433bc370bf23fac9cc591f01a8898',
    sourceUrl: '$_whisperSource/ggml-base-q5_1.bin',
    nVocab: _whisperVocab,
    nAudioState: 512,
    nAudioLayer: 6,
    nTextLayer: 6,
    nMels: _whisperMels,
    ftype: _q5Ftype,
    memoryEstimateBytes: 168 * _mebibyte,
    tier: SpeechModelTier.balanced,
  );

  /// The accurate model, imported by hand on native platforms only.
  static const SpeechModelEntry small = SpeechModelEntry(
    id: 'small-q5_1',
    kind: SpeechModelKind.whisper,
    fileName: 'ggml-small-q5_1.bin',
    bytes: 190085487,
    sha256: 'ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb',
    sourceUrl: '$_whisperSource/ggml-small-q5_1.bin',
    nVocab: _whisperVocab,
    nAudioState: 768,
    nAudioLayer: 12,
    nTextLayer: 12,
    nMels: _whisperMels,
    ftype: _q5Ftype,
    memoryEstimateBytes: 352 * _mebibyte,
    tier: SpeechModelTier.accurate,
    webAllowed: false,
  );

  /// The bundled Silero voice-activity model.
  static const SpeechModelEntry vad = SpeechModelEntry(
    id: 'silero-v6.2.0',
    kind: SpeechModelKind.vad,
    fileName: 'ggml-silero-v6.2.0.bin',
    asset: SpeechAssets.vadModel,
    bytes: 885098,
    sha256: '2aa269b785eeb53a82983a20501ddf7c1d9c48e33ab63a41391ac6c9f7fb6987',
    sourceUrl: '$_vadSource/ggml-silero-v6.2.0.bin',
    memoryEstimateBytes: 9 * _mebibyte,
    tier: null,
  );

  /// Every entry, whisper models from fastest to most accurate, then VAD.
  static const List<SpeechModelEntry> all = <SpeechModelEntry>[
    tiny,
    base,
    small,
    vad,
  ];

  /// The entry called [id], or null when the catalogue has none.
  static SpeechModelEntry? byId(String id) {
    for (final SpeechModelEntry entry in all) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  /// The import-only entry whose size and SHA-256 both equal the picked
  /// file's, or null when the file is not one the app accepts. [among] is
  /// the catalogue searched; a store's tests pass their own.
  static SpeechModelEntry? matchImport(
    int bytes,
    String sha256, {
    List<SpeechModelEntry> among = all,
  }) {
    final String digest = sha256.toLowerCase();
    for (final SpeechModelEntry entry in among) {
      if (entry.asset == null &&
          entry.bytes == bytes &&
          entry.sha256 == digest) {
        return entry;
      }
    }
    return null;
  }
}
