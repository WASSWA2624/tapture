import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/normalise/fuzzy_matcher.dart';

/// Scores a captured name against the Staff dataset with the shared fuzzy
/// matcher (FE-CONS-02).
///
/// Below the threshold nothing is offered, and nothing is ever linked here:
/// a person accepts a suggestion first.
final class AttendeeMatching {
  /// The closest staff row, by name or alias, at or above [threshold], with
  /// its score; null when none clears it.
  static StaffSuggestion? suggest({
    required String name,
    required List<StaffCandidate> staff,
    double? threshold,
  }) {
    final double cut = threshold ?? AppConstants.processing.fuzzyMatch;
    if (FuzzyMatcher.plain(name).isEmpty || staff.isEmpty) {
      return null;
    }
    StaffCandidate? best;
    var bestScore = 0.0;
    for (final StaffCandidate row in staff) {
      for (final String text in <String>[row.name, ...row.aliases]) {
        if (FuzzyMatcher.plain(text).isEmpty) {
          continue;
        }
        final double score = FuzzyMatcher.similarity(name, text);
        if (score > bestScore) {
          bestScore = score;
          best = row;
        }
      }
    }
    if (best == null || bestScore < cut) {
      return null;
    }
    return (staffId: best.id, name: best.name, score: bestScore);
  }
}

/// A staff row a captured name may be offered against.
typedef StaffCandidate = ({String id, String name, List<String> aliases});

/// A suggestion. Nothing is linked until a person accepts it.
typedef StaffSuggestion = ({String staffId, String name, double score});
