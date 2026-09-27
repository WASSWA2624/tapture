import 'lookup_matcher.dart';
import 'reference_row.dart';

/// Scored fuzzy fallback for a near-miss lookup.
///
/// Never fills silently — the caller shows a suggestion when the score clears
/// the binding threshold.
abstract final class FuzzyMatcher {
  /// Returns rows whose score against [query] on [column] meets [threshold],
  /// highest score first. Score is 0–1 from edit distance and token overlap.
  static List<({ReferenceRow row, double score})> rank({
    required List<ReferenceRow> rows,
    required String query,
    required String column,
    required double threshold,
  }) {
    final String needle = LookupMatcher.normalise(query);
    if (needle.isEmpty) {
      return const <({ReferenceRow row, double score})>[];
    }
    final List<({ReferenceRow row, double score})> hits =
        <({ReferenceRow row, double score})>[];
    for (final ReferenceRow row in rows) {
      final String hay = LookupMatcher.normalise(
        row.values[column] ?? (column.isEmpty ? row.key : ''),
      );
      if (hay.isEmpty) {
        continue;
      }
      final double score = scorePair(needle, hay);
      if (score >= threshold) {
        hits.add((row: row, score: score));
      }
    }
    hits.sort(
      (
        ({ReferenceRow row, double score}) a,
        ({ReferenceRow row, double score}) b,
      ) => b.score.compareTo(a.score),
    );
    return hits;
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
