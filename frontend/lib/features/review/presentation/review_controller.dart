import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/processing.dart'
    show processingRepositoryProvider;
import 'package:tapture/features/records/records.dart'
    show RecordValueEdit, recordRepositoryProvider;

import '../domain/approval_outcome.dart';
import '../review.dart' show reviewRepositoryProvider;
import 'raw_refined_toggle.dart' show ValueSide;
import 'review_approver.dart' show reviewApproverProvider;
import 'review_providers.dart' show reviewSideProvider;
import 'review_state.dart';

export 'review_state.dart';

/// One record's review state, by record id. Auto-dispose: only the open
/// review reads it (FE-STATE-09).
final reviewControllerProvider = NotifierProvider.autoDispose
    .family<ReviewController, ReviewState, String>(ReviewController.new);

/// The review of one record (task 016): the confident group, verifying,
/// the final side of a two-sided value, and re-analysis with its proposals.
///
/// The screen reads through providers and writes nothing itself. Value
/// edits go through the shared field editor; approval through the review
/// approver; everything else a person does on the review lands here.
final class ReviewController extends Notifier<ReviewState> {
  /// Creates the review of record [recordId].
  ReviewController(this.recordId);

  /// The record under review.
  final String recordId;

  @override
  ReviewState build() => const ReviewState();

  /// Opens or closes the confident group. It starts closed.
  void toggleConfident() {
    state = state.copyWith(confidentOpen: !state.confidentOpen);
  }

  /// Approves the record unless validation, a duplicate or a conflict
  /// blocks it, and names the next record of [queue] to review.
  Future<Result<ApprovalOutcome>> approve(List<String> queue) async {
    state = state.copyWith(busy: true, clearFailure: true);
    Result<ApprovalOutcome> result;
    try {
      result = await ref
          .read(reviewApproverProvider)
          .approve(recordId, queue: queue);
    } on Object catch (error) {
      result = FailureResult<ApprovalOutcome>(Failure.from(error));
    }
    if (ref.mounted) {
      state = state.copyWith(busy: false);
    }
    return result;
  }

  /// Marks [fieldKeys] verified without changing their values.
  Future<Result<void>> verify(List<String> fieldKeys) {
    return _run(
      () => ref.read(reviewRepositoryProvider).verify(recordId, fieldKeys),
    );
  }

  /// Makes [value], the [side] of [fieldKey], final, and remembers [side]
  /// as the side later fields start on. Both sides stay stored.
  Future<Result<void>> chooseSide(
    String fieldKey,
    ValueSide side,
    String value,
  ) {
    return _run(() async {
      await ref.read(reviewSideProvider.notifier).remember(side);
      return ref
          .read(reviewRepositoryProvider)
          .chooseFinal(recordId, fieldKey, value);
    });
  }

  /// Queues the record to be processed again. Its human work stays: what
  /// processing proposes afterwards is offered, never applied.
  Future<Result<void>> reanalyse() async {
    final Result<void> queued = await _run(() async {
      final Result<String> job = await ref
          .read(processingRepositoryProvider)
          .requeue(recordId);
      return job.map<void>((String _) {});
    });
    if (queued is Success<void> && ref.mounted) {
      state = state.copyWith(reanalysing: true, accepted: const <String>{});
    }
    return queued;
  }

  /// Ticks or unticks the proposal for [fieldKey].
  void toggleProposal(String fieldKey) {
    final Set<String> next = Set<String>.of(state.accepted);
    if (!next.add(fieldKey)) {
      next.remove(fieldKey);
    }
    state = state.copyWith(accepted: next);
  }

  /// Writes exactly the [accepted] proposals through the value editor's
  /// store, then closes the diff.
  Future<Result<void>> applyProposals(Map<String, String> accepted) async {
    final Result<void> written = await _run(
      () => ref
          .read(recordRepositoryProvider)
          .editValues(recordId, <RecordValueEdit>[
            for (final MapEntry<String, String> proposal in accepted.entries)
              (fieldKey: proposal.key, value: proposal.value),
          ]),
    );
    if (written is Success<void> && ref.mounted) {
      state = state.copyWith(reanalysing: false, accepted: const <String>{});
    }
    return written;
  }

  /// Declines every proposal: the record stays exactly as it was.
  void declineProposals() {
    state = state.copyWith(reanalysing: false, accepted: const <String>{});
  }

  /// Clears the failure banner.
  void dismissFailure() {
    state = state.copyWith(clearFailure: true);
  }

  /// Runs [write] with the busy flag up, keeping its failure for the banner.
  Future<Result<void>> _run(Future<Result<void>> Function() write) async {
    state = state.copyWith(busy: true, clearFailure: true);
    Result<void> result;
    try {
      result = await write();
    } on Object catch (error) {
      result = FailureResult<void>(Failure.from(error));
    }
    if (ref.mounted) {
      state = state.copyWith(
        busy: false,
        failure: result is FailureResult<void> ? result.failure : null,
      );
    }
    return result;
  }
}
