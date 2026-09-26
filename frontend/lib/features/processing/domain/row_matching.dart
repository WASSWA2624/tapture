import 'package:tapture/core/constants/app_constants.dart';

/// Resolves extracted text to a predefined row.
///
/// Exact, alias, normalised, fuzzy, then model classification. The first
/// strategy whose score clears [threshold] wins; a strategy that falls short
/// hands over to the next. Local strategies never call out, and [classify]
/// runs only after all four have failed.
final class RowMatching {
  /// The matched row, the strategy name and the score, or null.
  static Future<RowMatch?> match({
    required String query,
    required List<MatchableRow> rows,
    double? threshold,
    Future<RowMatch?> Function(String query, List<MatchableRow> rows)? classify,
  }) async {
    final double cut = threshold ?? AppConstants.processing.fuzzyMatch;
    final String trimmed = query.trim();
    if (trimmed.isEmpty || rows.isEmpty) {
      return null;
    }
    for (final MatchableRow row in rows) {
      if (row.label == trimmed || row.id == trimmed) {
        return (id: row.id, label: row.label, strategy: 'exact', score: 1.0);
      }
    }
    final String folded = trimmed.toLowerCase();
    for (final MatchableRow row in rows) {
      if (row.label.toLowerCase() == folded) {
        continue;
      }
      final double score = AppConstants.processing.rowMatchAliasScore;
      for (final String alias in row.aliases) {
        if (alias.toLowerCase() == folded && score >= cut) {
          return (
            id: row.id,
            label: row.label,
            strategy: 'alias',
            score: score,
          );
        }
      }
    }
    final String normalised = _normalise(trimmed);
    final double labelScore = AppConstants.processing.rowMatchNormalisedScore;
    final double aliasScore =
        AppConstants.processing.rowMatchNormalisedAliasScore;
    for (final MatchableRow row in rows) {
      if (_normalise(row.label) == normalised && labelScore >= cut) {
        return (
          id: row.id,
          label: row.label,
          strategy: 'normalised',
          score: labelScore,
        );
      }
      for (final String alias in row.aliases) {
        if (_normalise(alias) == normalised && aliasScore >= cut) {
          return (
            id: row.id,
            label: row.label,
            strategy: 'normalised',
            score: aliasScore,
          );
        }
      }
    }
    MatchableRow? fuzzyRow;
    var fuzzyScore = 0.0;
    for (final MatchableRow row in rows) {
      final double score = _ratio(normalised, _normalise(row.label));
      if (score > fuzzyScore) {
        fuzzyScore = score;
        fuzzyRow = row;
      }
    }
    if (fuzzyRow != null && fuzzyScore >= cut) {
      return (
        id: fuzzyRow.id,
        label: fuzzyRow.label,
        strategy: 'fuzzy',
        score: fuzzyScore,
      );
    }
    if (classify == null) {
      return null;
    }
    final RowMatch? model = await classify(trimmed, rows);
    if (model == null || model.score < cut) {
      return null;
    }
    return (
      id: model.id,
      label: model.label,
      strategy: 'model',
      score: model.score,
    );
  }
}

/// A predefined row the matcher may return.
typedef MatchableRow = ({String id, String label, List<String> aliases});

/// Why a row was chosen.
typedef RowMatch = ({String id, String label, String strategy, double score});

String _normalise(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

double _ratio(String left, String right) {
  if (left.isEmpty || right.isEmpty) {
    return 0;
  }
  if (left == right) {
    return 1;
  }
  final int distance = _levenshtein(left, right);
  final int longest = left.length > right.length ? left.length : right.length;
  return 1 - (distance / longest);
}

int _levenshtein(String left, String right) {
  final List<int> previous = List<int>.generate(right.length + 1, (int i) => i);
  final List<int> current = List<int>.filled(right.length + 1, 0);
  for (var i = 1; i <= left.length; i++) {
    current[0] = i;
    for (var j = 1; j <= right.length; j++) {
      final int cost = left[i - 1] == right[j - 1] ? 0 : 1;
      final int insert = current[j - 1] + 1;
      final int delete = previous[j] + 1;
      final int replace = previous[j - 1] + cost;
      var best = insert < delete ? insert : delete;
      if (replace < best) {
        best = replace;
      }
      current[j] = best;
    }
    for (var j = 0; j < previous.length; j++) {
      previous[j] = current[j];
    }
  }
  return previous[right.length];
}
