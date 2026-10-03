import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';

/// The moves a record's status may make (task 014 step 1, D4).
///
/// Callers check a move here before writing it and refuse an illegal one
/// with the [ValidationFailure] [check] returns. A move to the same status is
/// illegal. [RecordStatus.archived] and [RecordStatus.deleted] may move back
/// to any status that may move into them (restore), and to each other.
/// The manual path is draft, then needsReview, then approved; it never
/// touches a processing state.
abstract final class RecordLifecycle {
  /// Every status a record may move to from [from]. Never holds [from].
  static Set<RecordStatus> targetsFrom(RecordStatus from) => _table[from]!;

  /// Whether a record may move from [from] to [to].
  static bool allows(RecordStatus from, RecordStatus to) =>
      targetsFrom(from).contains(to);

  /// [Success] when the move from [from] to [to] is legal; otherwise a
  /// [ValidationFailure] naming why, with what to do instead.
  static Result<void> check(RecordStatus from, RecordStatus to) {
    if (from == to) {
      return FailureResult<void>(
        ValidationFailure(
          localizedMessage: DomainCopy.messages.failureThisRecordIsAlreadyValue(
            (_state[from]).toString(),
          ),
          localizedRecovery:
              DomainCopy.messages.failureChooseADifferentStatusOrLeaveIt,
        ),
      );
    }
    if (allows(from, to)) {
      return const Success<void>(null);
    }
    return FailureResult<void>(
      ValidationFailure(
        localizedMessage: DomainCopy.messages.failureARecordThatIsValueCannotBe(
          (_state[from]).toString(),
          (_target[to]).toString(),
        ),
        recoveryAction: _recovery(from, to),
      ),
    );
  }

  /// Whether moving from [from] to [to] brings a record back out of the
  /// recycle bin or the archive, rather than deleting or archiving it.
  static bool isRestore(RecordStatus from, RecordStatus to) {
    return (from == RecordStatus.archived || from == RecordStatus.deleted) &&
        to != RecordStatus.deleted &&
        allows(from, to);
  }

  /// The status a restore from [from] lands on: [previous] (the status the
  /// audit trail says the record had) when that is a legal restore, else
  /// [RecordStatus.needsReview], so a person looks at it again.
  static RecordStatus restoreTarget(RecordStatus from, RecordStatus? previous) {
    if (previous != null && isRestore(from, previous)) {
      return previous;
    }
    return RecordStatus.needsReview;
  }

  /// The status a record in [current] is left in after an operator changes
  /// its values, photos or template: approved goes back to review (§38).
  static RecordStatus afterEdit(RecordStatus current) {
    return current == RecordStatus.approved
        ? RecordStatus.needsReview
        : current;
  }

  /// [Success] when a record in [status] may have its values, photos or
  /// template changed; a deleted record must be restored first.
  static Result<void> checkEditable(RecordStatus status) {
    if (status != RecordStatus.deleted) {
      return const Success<void>(null);
    }
    return FailureResult<void>(
      ValidationFailure(
        localizedMessage:
            DomainCopy.messages.failureThisRecordIsInTheRecycleBin,
        localizedRecovery:
            DomainCopy.messages.failureRestoreItFromTheRecycleBinBefore,
      ),
    );
  }
}

/// The forward moves of D4. Archived and deleted are derived from them.
const Map<RecordStatus, Set<RecordStatus>> _forward =
    <RecordStatus, Set<RecordStatus>>{
      RecordStatus.draft: <RecordStatus>{
        RecordStatus.captured,
        RecordStatus.queued,
        RecordStatus.needsReview,
        RecordStatus.archived,
        RecordStatus.deleted,
      },
      RecordStatus.captured: <RecordStatus>{
        RecordStatus.queued,
        RecordStatus.processing,
        RecordStatus.extracted,
        RecordStatus.needsReview,
        RecordStatus.failed,
        RecordStatus.archived,
        RecordStatus.deleted,
      },
      RecordStatus.queued: <RecordStatus>{
        RecordStatus.processing,
        RecordStatus.captured,
        RecordStatus.failed,
        RecordStatus.archived,
        RecordStatus.deleted,
      },
      RecordStatus.processing: <RecordStatus>{
        RecordStatus.extracted,
        RecordStatus.needsReview,
        RecordStatus.failed,
        RecordStatus.queued,
      },
      RecordStatus.extracted: <RecordStatus>{
        RecordStatus.needsReview,
        RecordStatus.approved,
        RecordStatus.queued,
        RecordStatus.archived,
        RecordStatus.deleted,
      },
      RecordStatus.needsReview: <RecordStatus>{
        RecordStatus.approved,
        RecordStatus.queued,
        RecordStatus.archived,
        RecordStatus.deleted,
      },
      RecordStatus.approved: <RecordStatus>{
        RecordStatus.needsReview,
        RecordStatus.queued,
        RecordStatus.archived,
        RecordStatus.deleted,
      },
      RecordStatus.failed: <RecordStatus>{
        RecordStatus.queued,
        RecordStatus.needsReview,
        RecordStatus.archived,
        RecordStatus.deleted,
      },
    };

final Map<RecordStatus, Set<RecordStatus>> _table = _build();

Map<RecordStatus, Set<RecordStatus>> _build() {
  Set<RecordStatus> into(RecordStatus parked, RecordStatus other) {
    return Set<RecordStatus>.unmodifiable(<RecordStatus>{
      for (final MapEntry<RecordStatus, Set<RecordStatus>> move
          in _forward.entries)
        if (move.value.contains(parked)) move.key,
      other,
    });
  }

  return <RecordStatus, Set<RecordStatus>>{
    for (final MapEntry<RecordStatus, Set<RecordStatus>> move
        in _forward.entries)
      move.key: Set<RecordStatus>.unmodifiable(move.value),
    RecordStatus.archived: into(RecordStatus.archived, RecordStatus.deleted),
    RecordStatus.deleted: into(RecordStatus.deleted, RecordStatus.archived),
  };
}

/// How "this record is …" reads for each status.
const Map<RecordStatus, String> _state = <RecordStatus, String>{
  RecordStatus.draft: 'a draft',
  RecordStatus.captured: 'captured',
  RecordStatus.queued: 'queued',
  RecordStatus.processing: 'being processed',
  RecordStatus.extracted: 'extracted',
  RecordStatus.needsReview: 'waiting for review',
  RecordStatus.approved: 'approved',
  RecordStatus.failed: 'failed',
  RecordStatus.archived: 'archived',
  RecordStatus.deleted: 'in the recycle bin',
};

/// How "cannot be …" reads for each destination.
const Map<RecordStatus, String> _target = <RecordStatus, String>{
  RecordStatus.draft: 'made a draft again',
  RecordStatus.captured: 'marked captured',
  RecordStatus.queued: 'queued',
  RecordStatus.processing: 'processed',
  RecordStatus.extracted: 'marked extracted',
  RecordStatus.needsReview: 'sent to review',
  RecordStatus.approved: 'approved',
  RecordStatus.failed: 'marked failed',
  RecordStatus.archived: 'archived',
  RecordStatus.deleted: 'deleted',
};

String _recovery(RecordStatus from, RecordStatus to) {
  if (from == RecordStatus.deleted) {
    return 'Restore it from the recycle bin first.';
  }
  if (from == RecordStatus.processing) {
    return 'Wait for processing to finish, then try again.';
  }
  if (to == RecordStatus.approved) {
    return 'Send it to review first, then approve it.';
  }
  return 'Choose one of the actions this record offers.';
}
