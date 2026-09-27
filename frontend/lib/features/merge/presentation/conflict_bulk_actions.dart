import '../domain/conflict_choice.dart';

/// Writes one audit line per conflict a bulk action settles (task 019).
final class ConflictBulkActions {
  /// One entry per [conflictIds], each naming [chooser].
  static List<ConflictAudit> settle({
    required List<String> conflictIds,
    required ConflictChoice choice,
    required String chooser,
  }) {
    return <ConflictAudit>[
      for (final String id in conflictIds)
        (conflictId: id, choice: choice, chooser: chooser),
    ];
  }
}

/// One conflict a person settled.
typedef ConflictAudit = ({
  String conflictId,
  ConflictChoice choice,
  String chooser,
});
