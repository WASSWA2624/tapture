import 'package:tapture/core/constants/app_constants.dart';

/// Scores a captured name against the Staff dataset.
///
/// The ratio is the same normalised edit distance the row matcher uses.
/// Below the threshold nothing is offered.
final class AttendeeMatching {
  /// The closest staff row at or above [threshold], or null.
  static StaffSuggestion? suggest({
    required String name,
    required List<StaffCandidate> staff,
    double? threshold,
  }) {
    final double cut = threshold ?? AppConstants.processing.fuzzyMatch;
    final String query = _normalise(name);
    if (query.isEmpty || staff.isEmpty) {
      return null;
    }
    StaffCandidate? best;
    var bestScore = 0.0;
    for (final StaffCandidate row in staff) {
      final double score = _best(query, row);
      if (score > bestScore) {
        bestScore = score;
        best = row;
      }
    }
    if (best == null || bestScore < cut) {
      return null;
    }
    return (staffId: best.id, name: best.name, score: bestScore);
  }

  static double _best(String query, StaffCandidate row) {
    var best = _ratio(query, _normalise(row.name));
    for (final String alias in row.aliases) {
      final double score = _ratio(query, _normalise(alias));
      if (score > best) {
        best = score;
      }
    }
    return best;
  }

  static String _normalise(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static double _ratio(String left, String right) {
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

  static int _levenshtein(String left, String right) {
    final List<int> previous = List<int>.generate(
      right.length + 1,
      (int i) => i,
    );
    final List<int> current = List<int>.filled(right.length + 1, 0);
    for (var i = 1; i <= left.length; i++) {
      current[0] = i;
      for (var j = 1; j <= right.length; j++) {
        final int cost = left[i - 1] == right[j - 1] ? 0 : 1;
        final int insert = current[j - 1] + 1;
        final int remove = previous[j] + 1;
        final int replace = previous[j - 1] + cost;
        var best = insert < remove ? insert : remove;
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
}

/// A staff row a captured name may be offered against.
typedef StaffCandidate = ({String id, String name, List<String> aliases});

/// A suggestion. Nothing is linked until a person accepts it.
typedef StaffSuggestion = ({String staffId, String name, double score});
