import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/processing/processing.dart'
    show ProcessingRepository, processingRepositoryProvider;
import 'package:tapture/features/review/review.dart'
    show
        ApprovalOutcome,
        Approved,
        Blocked,
        ReviewApprover,
        reviewApproverProvider;

import '../domain/record_repository.dart';
import '../records.dart' show recordRepositoryProvider;

/// Which bulk action is running over one project's selection, or null when
/// none is. Keyed by project id, like the selection it acts on.
/// Auto-dispose: the list's action bar is its only reader (FE-STATE-09).
final recordBulkControllerProvider = NotifierProvider.autoDispose
    .family<RecordBulkController, RecordBulkOperation?, String>(
      RecordBulkController.new,
    );

/// Approves, archives and processes again a selection of one project's
/// records (task 014 step 8). Delete goes through `RecordDeleteAction`, and
/// export through the project's export.
///
/// Each record is written on its own, in the order given, so one failure
/// neither stops nor rolls back the others: the outcome names every record
/// that changed and every one that did not, with why. A status move goes
/// through the repository, which checks it against the record lifecycle, so
/// a record that may not move is reported and left as it was.
final class RecordBulkController extends Notifier<RecordBulkOperation?> {
  /// Creates the controller for [projectId]'s selection.
  RecordBulkController(this.projectId);

  /// The project whose selected records the actions change.
  final String projectId;

  /// The reason stored on the audit entry of a bulk approval.
  static const String approveReason = 'Approved in bulk by the operator.';

  /// The reason stored on the audit entry of a bulk archive.
  static const String archiveReason = 'Archived in bulk by the operator.';

  @override
  RecordBulkOperation? build() => null;

  /// Whether a bulk action is running, so the bar holds its controls.
  bool get isBusy => state != null;

  /// Approves every record in [ids] through review's one approval path, so
  /// a validation error, an unresolved duplicate or an unresolved conflict
  /// leaves that record as it was, reported with the field and the reason
  /// (task 016). A record the lifecycle does not let move to approved, such
  /// as one not yet processed, fails validation and is left as it was.
  Future<RecordBulkOutcome> approve(List<String> ids) {
    final ReviewApprover approver = ref.read(reviewApproverProvider);
    return _each(RecordBulkOperation.approve, ids, (String id) async {
      final Result<ApprovalOutcome> approved = await approver.approve(
        id,
        reason: approveReason,
      );
      return switch (approved) {
        Success<ApprovalOutcome>(value: Approved()) => const Success<void>(
          null,
        ),
        Success<ApprovalOutcome>(value: Blocked(:final reasons)) =>
          FailureResult<void>(
            ValidationFailure(
              message: reasons.isEmpty
                  ? Copy.reviewBlockedAction
                  : reasons.first.message,
              localizedRecovery: Copy.messages.reviewBlockedAction,
            ),
          ),
        FailureResult<ApprovalOutcome>(:final Failure failure) =>
          FailureResult<void>(failure),
      };
    });
  }

  /// Archives every record in [ids]: out of the list and default exports,
  /// every value and photo kept.
  Future<RecordBulkOutcome> archive(List<String> ids) {
    final RecordRepository records = ref.read(recordRepositoryProvider);
    return _each(
      RecordBulkOperation.archive,
      ids,
      (String id) =>
          records.transition(id, RecordStatus.archived, reason: archiveReason),
    );
  }

  /// Puts every record in [ids] back in the processing queue from the first
  /// step (D14): each record's job starts over and the record moves to
  /// queued. Running the queue is the caller's next step.
  Future<RecordBulkOutcome> reprocess(List<String> ids) {
    final ProcessingRepository processing = ref.read(
      processingRepositoryProvider,
    );
    return _each(RecordBulkOperation.reprocess, ids, (String id) async {
      final Result<String> queued = await processing.requeue(id);
      return queued.map<void>((String _) {});
    });
  }

  Future<RecordBulkOutcome> _each(
    RecordBulkOperation operation,
    List<String> ids,
    Future<Result<void>> Function(String id) write,
  ) async {
    final List<String> targets = <String>{...ids}.toList();
    final List<String> succeeded = <String>[];
    final Map<String, Failure> failed = <String, Failure>{};
    if (targets.isEmpty) {
      return (succeeded: succeeded, failed: failed);
    }
    if (state != null) {
      return (
        succeeded: List<String>.unmodifiable(succeeded),
        failed: Map<String, Failure>.unmodifiable(<String, Failure>{
          for (final String id in targets) id: _busy,
        }),
      );
    }
    state = operation;
    try {
      for (final String id in targets) {
        final Result<void> written = await _guard(() => write(id));
        switch (written) {
          case Success<void>():
            succeeded.add(id);
          case FailureResult<void>(:final Failure failure):
            failed[id] = failure;
        }
      }
    } finally {
      if (ref.mounted) {
        state = null;
      }
    }
    return (
      succeeded: List<String>.unmodifiable(succeeded),
      failed: Map<String, Failure>.unmodifiable(failed),
    );
  }
}

/// A bulk action over a selection, as the action bar names it.
enum RecordBulkOperation {
  /// Move to approved.
  approve,

  /// Move to archived.
  archive,

  /// Put back in the processing queue.
  reprocess,
}

/// What a bulk action did: the records it changed, in the order asked, and
/// the ones it could not change, each with the failure that stopped it. The
/// same shape as `RecordDeleteOutcome`, so a bulk delete reports alike.
typedef RecordBulkOutcome = ({
  List<String> succeeded,
  Map<String, Failure> failed,
});

/// Runs [call], turning a store that throws into a [FailureResult] so one bad
/// record cannot end the run.
Future<Result<void>> _guard(Future<Result<void>> Function() call) async {
  try {
    return await call();
  } on Object catch (error) {
    return FailureResult<void>(Failure.from(error));
  }
}

final ValidationFailure _busy = ValidationFailure(
  localizedMessage: Copy.messages.recordsBulkBusy,
  localizedRecovery: Copy.messages.recordsBulkBusyAction,
);
