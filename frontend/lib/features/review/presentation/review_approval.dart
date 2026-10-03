import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import '../domain/approval_outcome.dart';
import 'review_approver.dart';

/// Approves one record from a screen and says what happened (task 016).
///
/// Every approval a person makes on a page comes through the review
/// approver, so each one validates and blocks on an unresolved duplicate or
/// conflict, naming the field and the reason.
abstract final class ReviewApproval {
  /// Approves [recordId] unless something blocks it, then shows the
  /// outcome. [queue] is the review order the next record is taken from.
  ///
  /// Returns the outcome, or null when the store refused the approval.
  static Future<ApprovalOutcome?> approve(
    BuildContext context,
    WidgetRef ref, {
    required String recordId,
    List<String> queue = const <String>[],
  }) async {
    Result<ApprovalOutcome> result;
    try {
      result = await ref
          .read(reviewApproverProvider)
          .approve(recordId, queue: queue);
    } on Object catch (error) {
      result = FailureResult<ApprovalOutcome>(Failure.from(error));
    }
    if (!context.mounted) {
      return result is Success<ApprovalOutcome> ? result.value : null;
    }
    return report(context, result);
  }

  /// Shows what an approval did: approved, blocked with the first reason,
  /// or refused by the store. Returns the outcome, or null when refused.
  static ApprovalOutcome? report(
    BuildContext context,
    Result<ApprovalOutcome> result,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    switch (result) {
      case Success<ApprovalOutcome>(:final ApprovalOutcome value):
        switch (value) {
          case Approved():
            showAppSnack(
              context,
              localCopy.recordsApproved(1),
              tone: SnackTone.success,
            );
          case Blocked(:final List<ValidationIssue> reasons):
            showAppSnack(
              context,
              reasons.isEmpty
                  ? localCopy.reviewBlockedAction
                  : reasons.first.message,
              tone: SnackTone.error,
            );
        }
        return value;
      case FailureResult<ApprovalOutcome>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
        return null;
    }
  }
}
