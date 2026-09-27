import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';

import '../domain/record_history_event.dart';
import '../domain/record_lifecycle.dart';
import '../domain/record_repository.dart';
import '../records.dart' show recordRepositoryProvider;

/// The status moves of the record id it is created with, from its page.
/// Auto-dispose: the record page is its only reader (FE-STATE-09); an undo
/// on a snack still reaches the store after the page has closed, because
/// the store is held from the last build.
final recordDetailControllerProvider = NotifierProvider.autoDispose
    .family<RecordDetailController, RecordDetailState, String>(
      RecordDetailController.new,
    );

/// Approves, sends to review, archives and unarchives one record from its
/// page (task 014 step 4).
///
/// Every move is checked with [RecordLifecycle] before anything is written,
/// so an illegal one is refused with the reason and nothing changes; a
/// record in the recycle bin is restored through the delete controller, never
/// moved here. A refused or failed move is kept in [state] for the page to
/// show; the next move that succeeds clears it.
final class RecordDetailController extends Notifier<RecordDetailState> {
  /// Creates the controller for [recordId].
  RecordDetailController(this.recordId);

  /// The record whose status moves.
  final String recordId;

  /// The reason stored on the audit entry when a record is approved from
  /// its page. Stored data, not screen text.
  static const String approveReason = 'Approved on the record page.';

  /// The reason stored when a record is sent to review from its page.
  static const String reviewReason = 'Sent to review on the record page.';

  /// The reason stored when a record is archived from its page.
  static const String archiveReason = 'Archived on the record page.';

  /// The reason stored when a record is brought back from the archive.
  static const String unarchiveReason = 'Unarchived on the record page.';

  /// Held so an undo from a snack still reaches the store after the page
  /// that moved the record has closed.
  late RecordRepository _records;

  @override
  RecordDetailState build() {
    _records = ref.watch(recordRepositoryProvider);
    return _idle;
  }

  /// Whether a record in [status] may be approved from its page: it has
  /// been read or reviewed, and is neither archived nor in the recycle bin.
  static bool canApprove(RecordStatus status) {
    return !_parked(status) &&
        RecordLifecycle.allows(status, RecordStatus.approved);
  }

  /// Whether a record in [status] may be sent to review by hand: a draft, a
  /// capture nobody processed, or a run that failed. The manual path is
  /// draft, then review, then approved, with no processing state.
  static bool canSendToReview(RecordStatus status) {
    return _toReview.contains(status) &&
        RecordLifecycle.allows(status, RecordStatus.needsReview);
  }

  /// Whether a record in [status] may be archived from its page.
  static bool canArchive(RecordStatus status) {
    return !_parked(status) &&
        RecordLifecycle.allows(status, RecordStatus.archived);
  }

  /// Whether a record in [status] may be brought back from the archive.
  static bool canUnarchive(RecordStatus status) {
    return status == RecordStatus.archived;
  }

  /// Whether a record in [status] may be moved to the recycle bin.
  static bool canDelete(RecordStatus status) {
    return status != RecordStatus.deleted &&
        RecordLifecycle.allows(status, RecordStatus.deleted);
  }

  /// The status [history] says the record had before it last moved to
  /// [current]: the previous value of the latest status line whose new
  /// value is [current]. Null when no such line is known.
  static RecordStatus? statusBefore(
    List<RecordHistoryEvent> history,
    RecordStatus current,
  ) {
    for (final RecordHistoryEvent event in history.reversed) {
      if (event.kind != RecordHistoryKind.statusChanged) {
        continue;
      }
      if (RecordStatus.fromStored(event.next ?? '') != current) {
        continue;
      }
      return RecordStatus.fromStored(event.previous ?? '');
    }
    return null;
  }

  /// Approves the record, which is in [from] now.
  Future<Result<void>> approve(RecordStatus from) {
    return _move(from, RecordStatus.approved, approveReason);
  }

  /// Sends the record, which is in [from] now, to review.
  Future<Result<void>> sendToReview(RecordStatus from) {
    return _move(from, RecordStatus.needsReview, reviewReason);
  }

  /// Archives the record, which is in [from] now. Its values and photos
  /// stay; it leaves the lists and default exports.
  Future<Result<void>> archive(RecordStatus from) {
    return _move(from, RecordStatus.archived, archiveReason);
  }

  /// Brings the archived record back to [previous], the status it had
  /// before it was archived, or to review when that is not known.
  Future<Result<void>> unarchive({RecordStatus? previous}) {
    return _move(
      RecordStatus.archived,
      RecordLifecycle.restoreTarget(RecordStatus.archived, previous),
      unarchiveReason,
    );
  }

  /// Hides the kept failure.
  void dismissFailure() {
    if (ref.mounted && state.failure != null) {
      state = _idle;
    }
  }

  Future<Result<void>> _move(
    RecordStatus from,
    RecordStatus to,
    String reason,
  ) async {
    if (ref.mounted && state.busy) {
      return const FailureResult<void>(_busy);
    }
    final Result<void> legal = _legal(from, to);
    if (legal case FailureResult<void>(:final Failure failure)) {
      _set((busy: false, failure: failure));
      return legal;
    }
    final RecordRepository records = _records;
    _set((busy: true, failure: null));
    Result<void> written;
    try {
      written = await records.transition(recordId, to, reason: reason);
    } on Object catch (error) {
      written = FailureResult<void>(Failure.from(error));
    }
    switch (written) {
      case Success<void>():
        _set(_idle);
      case FailureResult<void>(:final Failure failure):
        _set((busy: false, failure: failure));
    }
    return written;
  }

  /// A record in the recycle bin is restored, never moved; every other move
  /// is checked against the lifecycle.
  Result<void> _legal(RecordStatus from, RecordStatus to) {
    final Result<void> editable = RecordLifecycle.checkEditable(from);
    if (editable is FailureResult<void>) {
      return editable;
    }
    return RecordLifecycle.check(from, to);
  }

  void _set(RecordDetailState next) {
    if (ref.mounted) {
      state = next;
    }
  }
}

/// Archived and deleted records are parked: they are brought back first,
/// never approved or archived again from their page.
bool _parked(RecordStatus status) {
  return status == RecordStatus.archived || status == RecordStatus.deleted;
}

/// The statuses a person may send to review by hand.
const Set<RecordStatus> _toReview = <RecordStatus>{
  RecordStatus.draft,
  RecordStatus.captured,
  RecordStatus.failed,
};

const RecordDetailState _idle = (busy: false, failure: null);

const ValidationFailure _busy = ValidationFailure(
  message: Copy.recordDetailBusy,
  recoveryAction: Copy.recordDetailBusyAction,
);

/// Whether a status move is being written, and the last move that was
/// refused or failed, with why.
typedef RecordDetailState = ({bool busy, Failure? failure});
