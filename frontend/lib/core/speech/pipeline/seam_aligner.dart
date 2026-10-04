import 'dart:math' as math;

import '../transcript_word.dart';
import 'word_sequence.dart';

/// Joins the two utterances on either side of a hard cut without
/// repeating or losing a word (spec §30.4.7).
///
/// After a hard cut the next utterance decodes the seam overlap again,
/// `R = [seamFrom, cut)`, so both decodes hold the words said there, each
/// least reliable at its own window edge and both timed loosely by whisper.
/// So the previous utterance stores its words up to the seam and holds back
/// the ones reaching into it ([heldFrom]); it is never edited after it is
/// stored. When the next utterance is decoded, the held words and its
/// leading words are aligned by text ([join]): of the runs of words both
/// read the same, the one that best joins the end of the held words to the
/// start of the next utterance wins (a phrase said twice near the seam
/// matches twice), the held words are kept up to it and the next
/// utterance's words follow. A run's words match by key; a word an edge
/// split matches the whole word as a fragment (prefix or suffix), and a
/// word of four or more letters within one edit, and the whole word is
/// kept. With no run at all, both are kept: whisper times words at a
/// window's edge too loosely to drop any by time alone.
///
/// Only a hard cut shares audio. Utterances ended by silence, a soft cut
/// or a pause share none, so no text is ever deduplicated there: speech
/// repeated across a pause is kept.
abstract final class SeamAligner {
  /// Where the trailing [words] of an utterance ended by a hard cut start
  /// to be held back for the next one: the first of the run of last words
  /// that end after [seamFrom], less [tolerance].
  static int heldFrom(
    List<TranscriptWord> words, {
    required int seamFrom,
    required int tolerance,
  }) {
    int from = words.length;
    while (from > 0 && words[from - 1].endSample > seamFrom - tolerance) {
      from--;
    }
    return from;
  }

  /// The words that follow the stored text across the cut at [cut]: the
  /// [held] words of the previous utterance and the [next] utterance's
  /// words, each pick naming its source and index, with [tolerance]
  /// samples of timing slack. [context] is the last word the previous
  /// utterance stored, if any: a run may start at it, and the next
  /// utterance's words before it are then already said.
  ///
  /// Held words before the run come first, then the next utterance's
  /// confident words before it (the two decodes heard that stretch
  /// differently, and each may hold a word the other missed; a word below
  /// [weakLogProbability] there is the next window's misheard edge), then
  /// the run (for a pair where one side holds only a fragment, the whole
  /// word), then the rest of the next utterance.
  static List<({bool held, int index})> join({
    required List<TranscriptWord> held,
    required List<TranscriptWord> next,
    required int cut,
    required int tolerance,
    required double weakLogProbability,
    TranscriptWord? context,
  }) {
    final List<TranscriptWord> earlier = <TranscriptWord>[?context, ...held];
    final int offset = context == null ? 0 : 1;
    // The next utterance's words in the seam, with the slack and one word
    // more, because whisper's times stray further than any fixed slack.
    int head = 0;
    while (head < next.length && next[head].startSample < cut + tolerance) {
      head++;
    }
    if (head < next.length) {
      head++;
    }
    final List<String> a = <String>[
      for (final TranscriptWord word in earlier) WordSequence.key(word.text),
    ];
    final List<String> b = <String>[
      for (final TranscriptWord word in next.take(head))
        WordSequence.key(word.text),
    ];
    _Run? best;
    for (int i = 0; i < a.length; i++) {
      for (int j = 0; j < b.length; j++) {
        final _Run? run = _runAt(a, b, i, j, earlier, next);
        if (run != null && (best == null || run.beats(best))) {
          best = run;
        }
      }
    }
    if (best == null) {
      return <({bool held, int index})>[
        for (int index = 0; index < held.length; index++)
          (held: true, index: index),
        for (int index = 0; index < next.length; index++)
          (held: false, index: index),
      ];
    }
    final _Run run = best;
    final bool fromContext = run.i < offset;
    final List<({bool held, int index})> picks = <({bool held, int index})>[
      for (int index = offset; index < run.i; index++)
        (held: true, index: index - offset),
      if (!fromContext)
        for (int index = 0; index < run.j; index++)
          if (_confident(next[index], weakLogProbability))
            (held: false, index: index),
    ];
    for (int pair = 0; pair < run.length; pair++) {
      final int i = run.i + pair;
      final int j = run.j + pair;
      if (i < offset) {
        continue;
      }
      // A fragment of a word the other side heard whole gives way to it.
      final bool nextIsPiece = _isFragment(b[j], of: a[i], atEnd: true);
      picks.add(
        nextIsPiece ? (held: true, index: i - offset) : (held: false, index: j),
      );
    }
    for (int index = run.j + run.length; index < next.length; index++) {
      picks.add((held: false, index: index));
    }
    return picks;
  }

  static bool _confident(TranscriptWord word, double weakLogProbability) =>
      word.probability > 0 && math.log(word.probability) >= weakLogProbability;

  /// The run of matching words starting at held word [i] and next word
  /// [j], or null when they do not match.
  static _Run? _runAt(
    List<String> a,
    List<String> b,
    int i,
    int j,
    List<TranscriptWord> earlier,
    List<TranscriptWord> next,
  ) {
    int length = 0;
    int exact = 0;
    while (i + length < a.length && j + length < b.length) {
      final String earlier = a[i + length];
      final String later = b[j + length];
      if (earlier == later && earlier.isNotEmpty) {
        exact++;
      } else if (!_alike(
        earlier,
        later,
        nextStarts: j + length == 0,
        heldEnds: i + length == a.length - 1,
      )) {
        break;
      }
      length++;
    }
    if (length == 0) {
      return null;
    }
    return _Run(
      i: i,
      j: j,
      length: length,
      exact: exact,
      drift: (earlier[i].startSample - next[j].startSample).abs(),
      // The seam joins the end of the held words to the start of the next
      // utterance: held words left after the run, and next words before
      // it, count against a run.
      fit: length - (a.length - i - length) - j,
    );
  }

  /// Whether two different words read as one: the next utterance's first
  /// word ([nextStarts]) as the end of a held word its window began inside,
  /// the last held word ([heldEnds]) as the start of a word the cut split,
  /// or two words of four or more letters a letter apart.
  static bool _alike(
    String held,
    String next, {
    required bool nextStarts,
    required bool heldEnds,
  }) =>
      (nextStarts && _isFragment(next, of: held, atEnd: true)) ||
      (heldEnds && _isFragment(held, of: next, atEnd: false)) ||
      _closeSpelling(held, next);

  /// Whether [part] is a non-empty piece of [of]: its end when [atEnd], its
  /// start otherwise.
  static bool _isFragment(
    String part, {
    required String of,
    required bool atEnd,
  }) =>
      part.isNotEmpty &&
      part.length < of.length &&
      (atEnd ? of.endsWith(part) : of.startsWith(part));

  /// Whether two words of four or more letters differ by at most one edit.
  static bool _closeSpelling(String a, String b) {
    if (a.length < _minEditLength || b.length < _minEditLength) {
      return false;
    }
    if ((a.length - b.length).abs() > 1) {
      return false;
    }
    int i = 0;
    int j = 0;
    int edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) {
        return false;
      }
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }
}

/// One run of held and next words that read alike.
final class _Run {
  const _Run({
    required this.i,
    required this.j,
    required this.length,
    required this.exact,
    required this.drift,
    required this.fit,
  });

  final int i;
  final int j;
  final int length;
  final int exact;
  final int drift;
  final int fit;

  /// The run that best joins the end of the held words to the start of the
  /// next utterance wins, then the longer, then the one with more identical
  /// words, then the one whose two decodes timed it closest.
  bool beats(_Run other) {
    if (fit != other.fit) {
      return fit > other.fit;
    }
    if (length != other.length) {
      return length > other.length;
    }
    if (exact != other.exact) {
      return exact > other.exact;
    }
    return drift < other.drift;
  }
}

/// Letters a word needs before a one-letter difference counts as the same
/// word.
const int _minEditLength = 4;
