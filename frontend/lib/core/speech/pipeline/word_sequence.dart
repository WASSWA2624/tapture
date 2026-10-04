import '../speech_piece.dart';
import '../transcript_word.dart';

/// How decoded text is cut into words and compared word by word, so drafts,
/// seams and loops all read words the same way (spec §30.4.7).
///
/// A word's key is its lower-case form without leading or trailing
/// punctuation, so "Country," and "country" are the same word.
abstract final class WordSequence {
  /// The words of [text]: split on white space, empties dropped.
  static List<String> words(String text) => <String>[
    for (final String word in text.split(_space))
      if (word.isNotEmpty) word,
  ];

  /// [word] lower-cased, without leading or trailing punctuation; typographic
  /// apostrophes read as plain ones.
  static String key(String word) => word
      .toLowerCase()
      .replaceAll(_curlyApostrophe, "'")
      .replaceAll(_edgePunctuation, '');

  /// The keys of [words], in order.
  static List<String> keys(Iterable<String> words) => <String>[
    for (final String word in words) key(word),
  ];

  /// How many leading words [a] and [b] share, compared by [key].
  static int commonPrefix(List<String> a, List<String> b) {
    final int length = a.length < b.length ? a.length : b.length;
    int index = 0;
    while (index < length && key(a[index]) == key(b[index])) {
      index++;
    }
    return index;
  }

  /// Timed words from a decode's [pieces]: a piece that starts with a space
  /// starts a word, any other piece continues the word before it, so
  /// sub-word pieces and trailing punctuation join their word. A word spans
  /// its pieces and has their mean probability.
  static List<TranscriptWord> fromPieces(List<SpeechPiece> pieces) {
    final List<TranscriptWord> words = <TranscriptWord>[];
    final StringBuffer text = StringBuffer();
    int start = 0;
    int end = 0;
    double probability = 0;
    int count = 0;
    void close() {
      final String word = text.toString().trim();
      if (word.isNotEmpty) {
        words.add(
          TranscriptWord(
            text: word,
            startSample: start,
            endSample: end < start ? start : end,
            probability: probability / count,
          ),
        );
      }
      text.clear();
      count = 0;
      probability = 0;
    }

    for (final SpeechPiece piece in pieces) {
      if (piece.text.trim().isEmpty) {
        continue;
      }
      if (count > 0 && _startsWord(piece.text)) {
        close();
      }
      if (count == 0) {
        start = piece.startSample;
      }
      text.write(piece.text);
      end = piece.endSample;
      probability += piece.probability;
      count++;
    }
    if (count > 0) {
      close();
    }
    return words;
  }

  /// The words of [text] spread evenly over samples `[start, end)` with
  /// [probability] each, for a decode that returned no timed pieces.
  static List<TranscriptWord> spread(
    String text, {
    required int start,
    required int end,
    required double probability,
  }) {
    final List<String> found = words(text);
    if (found.isEmpty) {
      return const <TranscriptWord>[];
    }
    final int span = end > start ? end - start : 0;
    return <TranscriptWord>[
      for (int index = 0; index < found.length; index++)
        TranscriptWord(
          text: found[index],
          startSample: start + span * index ~/ found.length,
          endSample: start + span * (index + 1) ~/ found.length,
          probability: probability,
        ),
    ];
  }

  static bool _startsWord(String piece) =>
      piece.startsWith(' ') || piece.startsWith('\n');
}

final RegExp _space = RegExp(r'\s+');
final RegExp _curlyApostrophe = RegExp('[‘’]');
final RegExp _edgePunctuation = RegExp(r'^\p{P}+|\p{P}+$', unicode: true);
