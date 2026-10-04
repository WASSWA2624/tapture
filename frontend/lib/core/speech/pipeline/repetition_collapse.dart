import 'package:tapture/core/constants/app_constants.dart';

import '../transcript_word.dart';
import 'speech_pipeline_config.dart';
import 'word_sequence.dart';

/// Collapses the loops whisper falls into, where one phrase repeats far
/// beyond what was said (spec §30.4.7).
///
/// For phrase lengths from `loopMaxNgram` words down to one, a run of the
/// same phrase repeated at least `loopMinRepeatsPhrase` times (a single
/// word `loopMinRepeatsWord` times) is a loop when either its words
/// outnumber `loopWordsPerSecond` per second of speech the detector heard
/// in the utterance, or it is said faster than `minSecondsPerWord` a word.
/// A loop collapses to its first copy. Repetition a person really says,
/// such as "no, no, no" or a phrase said twice, is kept. A phrase that is
/// itself a shorter phrase repeated is left to that shorter length, so a
/// loop always collapses to its true unit.
abstract final class RepetitionCollapse {
  /// The indices of [words] a loop collapse removes, given [speechSamples]
  /// of detected speech in the utterance; empty when nothing loops.
  static Set<int> removals(
    List<TranscriptWord> words, {
    required int speechSamples,
    required SpeechPipelineConfig config,
  }) {
    final List<String> keys = WordSequence.keys(
      words.map((TranscriptWord word) => word.text),
    );
    final double speechSeconds = speechSamples / AppConstants.audio.sampleRate;
    final double wordLimit = speechSeconds * config.loopWordsPerSecond;
    final Set<int> removed = <int>{};
    for (int unit = config.loopMaxNgram; unit >= 1; unit--) {
      final int minRepeats = unit >= 2
          ? config.loopMinRepeatsPhrase
          : config.loopMinRepeatsWord;
      final List<int> alive = <int>[
        for (int index = 0; index < words.length; index++)
          if (!removed.contains(index)) index,
      ];
      int at = 0;
      while (at + unit * minRepeats <= alive.length) {
        if (_hasShorterPeriod(keys, alive, at, unit)) {
          at++;
          continue;
        }
        int repeats = 1;
        while (at + (repeats + 1) * unit <= alive.length &&
            _sameUnit(keys, alive, at, at + repeats * unit, unit)) {
          repeats++;
        }
        if (repeats < minRepeats) {
          at++;
          continue;
        }
        final int count = repeats * unit;
        final TranscriptWord first = words[alive[at]];
        final TranscriptWord last = words[alive[at + count - 1]];
        final double seconds =
            (last.endSample - first.startSample) /
            AppConstants.audio.sampleRate;
        if (count > wordLimit || seconds < count * config.minSecondsPerWord) {
          for (int index = at + unit; index < at + count; index++) {
            removed.add(alive[index]);
          }
          at += count;
        } else {
          at++;
        }
      }
    }
    return removed;
  }

  static bool _sameUnit(
    List<String> keys,
    List<int> alive,
    int a,
    int b,
    int unit,
  ) {
    for (int offset = 0; offset < unit; offset++) {
      if (keys[alive[a + offset]] != keys[alive[b + offset]]) {
        return false;
      }
    }
    return true;
  }

  /// Whether the phrase of [unit] words at [at] is a shorter phrase
  /// repeated.
  static bool _hasShorterPeriod(
    List<String> keys,
    List<int> alive,
    int at,
    int unit,
  ) {
    for (int period = 1; period < unit; period++) {
      if (unit % period != 0) {
        continue;
      }
      bool periodic = true;
      for (int offset = period; offset < unit && periodic; offset++) {
        periodic =
            keys[alive[at + offset]] == keys[alive[at + offset - period]];
      }
      if (periodic) {
        return true;
      }
    }
    return false;
  }
}
