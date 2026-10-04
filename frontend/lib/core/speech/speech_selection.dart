import 'package:tapture/core/constants/app_constants.dart';

import 'speech_decode_profile.dart';
import 'speech_model_entry.dart';

/// What the selector chose for this device and language: the whisper model,
/// the voice detector, the threads and the decode profiles (spec §30.4.2).
final class SpeechSelection {
  /// Describes one choice.
  const SpeechSelection({
    required this.model,
    required this.vad,
    required this.threads,
    required this.language,
    required this.interim,
    required this.committed,
    required this.reason,
    this.dictationCommitted,
  });

  /// The whisper model to load.
  final SpeechModelEntry model;

  /// The voice-activity model each lease opens.
  final SpeechModelEntry vad;

  /// Threads the model loads and decodes with.
  final int threads;

  /// The whisper language code, never `''` or `'auto'`.
  final String language;

  /// How a provisional partial is decoded: greedy, one segment, no
  /// timestamps, a short encoder context.
  final SpeechDecodeProfile interim;

  /// How a final utterance is decoded: temperature fallback and timestamps.
  final SpeechDecodeProfile committed;

  /// How a phone's short dictation final is decoded, or null where
  /// [committed] serves every final; see [dictationCommittedFor].
  final SpeechDecodeProfile? dictationCommitted;

  /// Why this model and these threads, in a few words, for the log.
  final String reason;

  /// How a dictation final of [sampleCount] samples is decoded: on a phone
  /// an utterance shorter than `mobileDictationShortUtterance` encodes only
  /// its own audio plus `mobileDictationCommittedPad` frames, which keeps a
  /// short final quick; everything else is [committed].
  SpeechDecodeProfile dictationCommittedFor(int sampleCount) {
    final SpeechDecodeProfile? short = dictationCommitted;
    if (short == null) {
      return committed;
    }
    final Duration limit =
        AppConstants.speechEngine.mobileDictationShortUtterance;
    final int limitSamples =
        limit.inMilliseconds *
        AppConstants.audio.sampleRate ~/
        Duration.millisecondsPerSecond;
    return sampleCount < limitSamples ? short : committed;
  }

  /// This selection for [language], keeping the model, threads and profiles.
  SpeechSelection forLanguage(String language) => SpeechSelection(
    model: model,
    vad: vad,
    threads: threads,
    language: language,
    interim: interim,
    committed: committed,
    reason: reason,
    dictationCommitted: dictationCommitted,
  );
}
