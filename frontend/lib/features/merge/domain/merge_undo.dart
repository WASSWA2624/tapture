import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Restores the snapshot taken before a merge, until it is purged.
final class MergeUndo {
  /// Creates an undo.
  const MergeUndo();

  /// Whether undo is still offered for [mergeId].
  bool isAvailable(String mergeId, {required bool purged}) {
    return mergeId.isNotEmpty && !purged;
  }

  /// The project as it was, including rows and files the merge removed, or
  /// a [StorageFailure] once the snapshot has been purged.
  Result<Map<String, String>> undo({
    required Map<String, String> snapshot,
    required bool purged,
  }) {
    if (purged) {
      return FailureResult<Map<String, String>>(_purged);
    }
    return Success<Map<String, String>>(<String, String>{...snapshot});
  }
}

final StorageFailure _purged = StorageFailure(
  localizedMessage: DomainCopy.messages.failureTheSnapshotHasBeenPurged,
  localizedRecovery: DomainCopy.messages.failureTheMergeCanNoLongerBeUndone,
);
