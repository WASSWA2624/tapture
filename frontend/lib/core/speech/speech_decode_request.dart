import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';

import 'speech_decode_kind.dart';
import 'speech_decode_profile.dart';

/// One window of audio to transcribe.
final class SpeechDecodeRequest {
  /// Asks for [samples] to be decoded in [language] as [kind] under
  /// [profile].
  const SpeechDecodeRequest({
    required this.samples,
    required this.language,
    required this.kind,
    required this.profile,
    this.offsetSamples = 0,
    this.prompt = '',
    this.pieceTimings = false,
  });

  /// 16 kHz mono audio in [-1, 1]; from 1 to
  /// `AppConstants.speechEngine.maxDecodeSamples` samples.
  final Float32List samples;

  /// A whisper language code such as `en`, never `''` or `'auto'`: language
  /// detection is a pass that cannot be aborted.
  final String language;

  /// Whether this is a disposable draft or a final.
  final SpeechDecodeKind kind;

  /// How the window is decoded.
  final SpeechDecodeProfile profile;

  /// Where `samples[0]` sits on the session timeline, in samples.
  final int offsetSamples;

  /// Text that conditions the decode. Never logged.
  final String prompt;

  /// Whether the result carries timed pieces.
  final bool pieceTimings;

  /// Whether every engine accepts this request: a sample count in range, a
  /// concrete language and a timeline offset that is not negative. An
  /// engine refuses any other request with `speechInvalidRequest()`.
  bool get isWellFormed =>
      samples.isNotEmpty &&
      samples.length <= AppConstants.speechEngine.maxDecodeSamples &&
      language.trim().isNotEmpty &&
      language != _detectLanguage &&
      offsetSamples >= 0;
}

/// whisper's request to detect the language, which the contract refuses.
const String _detectLanguage = 'auto';
