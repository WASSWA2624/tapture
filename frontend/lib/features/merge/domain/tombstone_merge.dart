import 'package:tapture/core/db/vector_relation.dart';

import 'version_vector.dart';

/// How a delete travels between devices without resurrecting a row (task 019).
final class TombstoneMerge {
  /// Resolves a delete against an edit.
  ///
  /// A delete that is later than the edit applies. An edit that post-dates
  /// the delete is a conflict. A delete already applied stays applied.
  static TombstoneOutcome resolve({
    required VersionVector deleteVector,
    required VersionVector? editVector,
    required bool alreadyApplied,
  }) {
    if (alreadyApplied) {
      return TombstoneOutcome.ignoreDelete;
    }
    if (editVector == null) {
      return TombstoneOutcome.applyDelete;
    }
    final VectorRelation relation = deleteVector.compareTo(editVector);
    if (relation == VectorRelation.dominated ||
        relation == VectorRelation.concurrent) {
      return TombstoneOutcome.conflictEditAfterDelete;
    }
    return TombstoneOutcome.applyDelete;
  }
}

/// The result of comparing a delete with an edit.
enum TombstoneOutcome {
  /// The delete is the later fact.
  applyDelete,

  /// This delete was already applied.
  ignoreDelete,

  /// Someone edited the row after it was deleted.
  conflictEditAfterDelete,
}
