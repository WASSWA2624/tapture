import 'dart:math';

import 'package:tapture/core/constants/app_constants.dart';

/// One scripted word: what was said and where, in samples on the session
/// timeline at 16 kHz. [endSample] is the sample after the word's last one.
typedef SpokenWord = ({String word, int startSample, int endSample});

/// What a test pretends was said, word by word, so the fake speech engine
/// can answer a decode with exactly the words its window holds, and a test
/// can compare a transcript with the truth (FE-TEST-04).
final class SpokenScript {
  /// A script of [words] in time order, never overlapping.
  SpokenScript(List<SpokenWord> words)
    : words = List<SpokenWord>.unmodifiable(words) {
    for (int index = 1; index < words.length; index++) {
      if (words[index].startSample < words[index - 1].endSample) {
        throw ArgumentError.value(words, 'words', 'overlap or are unordered');
      }
    }
  }

  /// [words] said one after another from [startSample], each lasting
  /// [wordDuration] with [gap] between them.
  factory SpokenScript.paced(
    List<String> words, {
    int startSample = 0,
    Duration wordDuration = const Duration(milliseconds: 400),
    Duration gap = const Duration(milliseconds: 200),
  }) {
    final int wordSamples = samplesOf(wordDuration);
    final int step = wordSamples + samplesOf(gap);
    return SpokenScript(<SpokenWord>[
      for (int index = 0; index < words.length; index++)
        (
          word: words[index],
          startSample: startSample + index * step,
          endSample: startSample + index * step + wordSamples,
        ),
    ]);
  }

  /// A script of [wordCount] words drawn from a fixed vocabulary with
  /// natural pacing: words of 200 to 600 ms, gaps of 50 to 300 ms, and
  /// about one pause in ten of 1 to 3 s. The same [random] seed gives the
  /// same script.
  factory SpokenScript.random(
    Random random, {
    required int wordCount,
    int startSample = 0,
    double pauseChance = 0.1,
  }) {
    final List<SpokenWord> words = <SpokenWord>[];
    int at = startSample;
    for (int index = 0; index < wordCount; index++) {
      final int length = samplesOf(
        Duration(milliseconds: 200 + random.nextInt(400)),
      );
      final String word = _vocabulary[random.nextInt(_vocabulary.length)];
      words.add((word: word, startSample: at, endSample: at + length));
      final bool pause = random.nextDouble() < pauseChance;
      at +=
          length +
          samplesOf(
            Duration(
              milliseconds: pause
                  ? 1000 + random.nextInt(2000)
                  : 50 + random.nextInt(250),
            ),
          );
    }
    return SpokenScript(words);
  }

  /// Nothing said at all.
  static final SpokenScript silence = SpokenScript(const <SpokenWord>[]);

  /// The words in time order.
  final List<SpokenWord> words;

  /// The words as one line of text, one space apart.
  String get text => words.map((SpokenWord word) => word.word).join(' ');

  /// The sample after the last word, or 0 for silence.
  int get endSample => words.isEmpty ? 0 : words.last.endSample;

  /// The words that overlap samples [from] to [to] at all.
  List<SpokenWord> overlapping(int from, int to) => <SpokenWord>[
    for (final SpokenWord word in words)
      if (word.endSample > from && word.startSample < to) word,
  ];

  /// Whether sample [sample] lies inside a word.
  bool isSpeechAt(int sample) => words.any(
    (SpokenWord word) => word.startSample <= sample && sample < word.endSample,
  );

  /// [duration] in samples at the speech sample rate.
  static int samplesOf(Duration duration) =>
      duration.inMicroseconds *
      AppConstants.audio.sampleRate ~/
      Duration.microsecondsPerSecond;
}

/// Words whose spelling a seam aligner can tell apart, including long ones
/// a window edge can cut in the middle.
const List<String> _vocabulary = <String>[
  'the',
  'pump',
  'station',
  'valve',
  'pressure',
  'reading',
  'country',
  'meter',
  'north',
  'tank',
  'seven',
  'twelve',
  'inspection',
  'cracked',
  'replaced',
  'gauge',
  'water',
  'supply',
  'operator',
  'checked',
];
