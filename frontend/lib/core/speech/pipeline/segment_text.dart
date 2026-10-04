import '../transcript_word.dart';

/// Tidies decoded text without changing what was said (spec §30.4.7).
///
/// White space is collapsed, bracketed or parenthesised tags of up to 40
/// characters such as `[BLANK_AUDIO]` or `(music)` and the music glyphs
/// `♪ ♫` are removed, and a space before `, . ; : ! ?` is dropped. Digits,
/// decimal points, times, thousands separators, versions, addresses and
/// ellipses are left exactly as decoded: the raw transcript stays verbatim
/// (FE-SEC-08), so `SpokenText.tidy` is deliberately not used here.
abstract final class SegmentText {
  /// [text] tidied.
  static String clean(String text) =>
      _tidy(text.replaceAll(_removed, ' ')).trim();

  /// Whether [text] holds no letter or digit: empty or punctuation only.
  static bool isBlank(String text) => !_wordCharacter.hasMatch(text);

  /// [words] tidied as one text: words inside a removed tag go, a word
  /// left with punctuation only joins the word before it (or goes when it
  /// leads), and every other word keeps its time and probability.
  static List<TranscriptWord> cleanWords(List<TranscriptWord> words) {
    final StringBuffer joined = StringBuffer();
    final List<int> starts = <int>[];
    final List<String> texts = <String>[];
    for (final TranscriptWord word in words) {
      final String text = word.text.trim();
      starts.add(joined.length);
      texts.add(text);
      joined
        ..write(text)
        ..write(' ');
    }
    final String all = joined.toString();
    final List<bool> removed = List<bool>.filled(all.length, false);
    for (final RegExpMatch match in _removed.allMatches(all)) {
      for (int index = match.start; index < match.end; index++) {
        removed[index] = true;
      }
    }
    final List<TranscriptWord> kept = <TranscriptWord>[];
    for (int index = 0; index < words.length; index++) {
      final StringBuffer left = StringBuffer();
      final int from = starts[index];
      for (int at = from; at < from + texts[index].length; at++) {
        if (!removed[at]) {
          left.write(all[at]);
        }
      }
      final String text = left.toString().replaceAll(_space, '');
      if (text.isEmpty) {
        continue;
      }
      if (isBlank(text)) {
        if (kept.isNotEmpty) {
          final TranscriptWord last = kept.removeLast();
          kept.add(_withText(last, '${last.text}$text'));
        }
        continue;
      }
      kept.add(_withText(words[index], text));
    }
    return kept;
  }

  /// The text of [words]: one space apart, none before punctuation.
  static String join(List<TranscriptWord> words) =>
      _tidy(words.map((TranscriptWord word) => word.text).join(' ')).trim();

  static String _tidy(String text) => text
      .replaceAll(_space, ' ')
      .replaceAllMapped(_spaceBeforeMark, (Match match) => match[1]!);

  static TranscriptWord _withText(TranscriptWord word, String text) =>
      TranscriptWord(
        text: text,
        startSample: word.startSample,
        endSample: word.endSample,
        probability: word.probability,
      );
}

/// Non-speech tags and music glyphs whisper writes over sounds.
final RegExp _removed = RegExp(r'[\[(][^\])]{0,40}[\])]|[♪♫]');
final RegExp _space = RegExp(r'\s+');
final RegExp _spaceBeforeMark = RegExp(r'\s+([,.;:!?])');
final RegExp _wordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);
