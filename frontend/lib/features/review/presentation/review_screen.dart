import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/records/records.dart';

import '../domain/approval_outcome.dart';
import 'review_approval.dart';
import 'review_body.dart';
import 'review_controller.dart';
import 'review_providers.dart';

/// One record's review (task 016): attention first, approvable in one tap.
///
/// Approve and next validates and approves the record, then opens the next
/// record waiting for review in the project, without going back to a list.
/// The body is [ReviewBody], which the batch queue shows too.
final class ReviewScreen extends ConsumerWidget {
  /// Creates the review of record [recordId] in project [projectId].
  const ReviewScreen({
    required this.projectId,
    required this.recordId,
    super.key,
  });

  /// The project the record belongs to.
  final String projectId;

  /// The record under review.
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordEntry? entry = ref.watch(recordEntryProvider(recordId)).value;
    final List<String> queue =
        ref.watch(reviewQueueProvider(projectId)).value ?? const <String>[];
    final bool busy = ref.watch(reviewControllerProvider(recordId)).busy;
    return AppPage(
      key: const ValueKey<String>('route-review'),
      title: entry == null ? localCopy.reviewTitle : reviewTitleOf(entry),
      subtitle: entry == null ? null : localCopy.reviewTitle,
      footer: entry == null || !canApproveInReview(entry)
          ? null
          : AppPrimaryAction(
              key: const ValueKey<String>('review-approve'),
              label: localCopy.reviewApproveNext,
              busy: busy,
              onPressed: () => unawaited(_approve(context, ref, queue)),
            ),
      body: ReviewBody(
        projectId: projectId,
        recordId: recordId,
        onBackToRecords: () => context.go(RoutePaths.projectRecords(projectId)),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    List<String> queue,
  ) async {
    // This record first, so the next is the first other record waiting.
    final Result<ApprovalOutcome> result = await ref
        .read(reviewControllerProvider(recordId).notifier)
        .approve(<String>[
          recordId,
          for (final String id in queue)
            if (id != recordId) id,
        ]);
    if (!context.mounted) {
      return;
    }
    final ApprovalOutcome? outcome = ReviewApproval.report(context, result);
    if (outcome is! Approved) {
      return;
    }
    final String? next = outcome.nextRecordId;
    if (next != null) {
      context.replace(RoutePaths.projectRecordReview(projectId, next));
      return;
    }
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(RoutePaths.projectRecords(projectId));
  }
}
