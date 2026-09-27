import 'search_text.dart';

/// Scored fuzzy comparison of two texts, shared by reference lookups and
/// the duplicate check (FE-STR-09).
///
/// Never fills or merges silently: a caller shows a suggestion, or asks a
/// person, when a score clears its threshold.
abstract final class FuzzyMatcher {
  /// Returns [items] whose text scores against [query] at [threshold] or
  /// above, highest score first. [textOf] reads an item's text, and
  /// [normalise] shapes both sides first ([plain] unless given). Score is
  /// 0–1 from edit distance and token overlap.
  static List<({T item, double score})> rank<T>({
    required Iterable<T> items,
    required String query,
    required String Function(T item) textOf,
    required double threshold,
    String Function(String text) normalise = plain,
  }) {
    final String needle = normalise(query);
    if (needle.isEmpty) {
      return <({T item, double score})>[];
    }
    final List<({T item, double score})> hits = <({T item, double score})>[];
    for (final T item in items) {
      final String hay = normalise(textOf(item));
      if (hay.isEmpty) {
        continue;
      }
      final double score = scorePair(needle, hay);
      if (score >= threshold) {
        hits.add((item: item, score: score));
      }
    }
    hits.sort(
      (({T item, double score}) a, ({T item, double score}) b) =>
          b.score.compareTo(a.score),
    );
    return hits;
  }

  /// How alike two texts read, 0–1, once both are [plain].
  static double similarity(String left, String right) {
    final String a = plain(left);
    final String b = plain(right);
    if (a.isEmpty || b.isEmpty) {
      return a == b ? 1 : 0;
    }
    return scorePair(a, b);
  }

  /// Folded with [foldSearchText], every run of anything but letters and
  /// digits one space, trimmed.
  static String plain(String text) {
    return foldSearchText(
      text,
    ).replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();
  }

  /// Combined normalised edit-distance and token-overlap score in 0–1.
  static double scorePair(String left, String right) {
    if (left == right) {
      return 1;
    }
    final double edit = _editScore(left, right);
    final double tokens = _tokenOverlap(left, right);
    return (edit * 0.6) + (tokens * 0.4);
  }

  static double _editScore(String left, String right) {
    final int distance = _levenshtein(left, right);
    final int longest = left.length > right.length ? left.length : right.length;
    if (longest == 0) {
      return 1;
    }
    return 1 - (distance / longest);
  }

  static double _tokenOverlap(String left, String right) {
    final Set<String> a = left
        .split(' ')
        .where((String t) => t.isNotEmpty)
        .toSet();
    final Set<String> b = right
        .split(' ')
        .where((String t) => t.isNotEmpty)
        .toSet();
    if (a.isEmpty || b.isEmpty) {
      return 0;
    }
    final int shared = a.intersection(b).length;
    final int union = a.union(b).length;
    return shared / union;
  }

  static int _levenshtein(String left, String right) {
    if (left == right) {
      return 0;
    }
    if (left.isEmpty) {
      return right.length;
    }
    if (right.isEmpty) {
      return left.length;
    }
    final List<int> prev = List<int>.generate(right.length + 1, (int i) => i);
    final List<int> curr = List<int>.filled(right.length + 1, 0);
    for (int i = 0; i < left.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < right.length; j++) {
        final int cost = left.codeUnitAt(i) == right.codeUnitAt(j) ? 0 : 1;
        final int del = prev[j + 1] + 1;
        final int ins = curr[j] + 1;
        final int sub = prev[j] + cost;
        curr[j + 1] = del < ins
            ? (del < sub ? del : sub)
            : (ins < sub ? ins : sub);
      }
      for (int j = 0; j < prev.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[right.length];
  }
}
