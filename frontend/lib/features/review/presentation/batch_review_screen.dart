import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../domain/approval_outcome.dart';
import 'review_approval.dart';
import 'review_body.dart';
import 'review_controller.dart';
import 'review_providers.dart';

/// The project's review queue, one record at a time (task 016 step 5).
///
/// Each record shows the same review as its own review page. Approve and
/// next validates and approves it and moves straight to the next record
/// waiting; Skip moves on without approving; Previous record goes back.
/// Edits are saved as they are made, so a record left and returned to
/// shows them intact, and forty records clear in one pass.
final class BatchReviewScreen extends ConsumerWidget {
  /// Creates the queue of project [projectId].
  const BatchReviewScreen({required this.projectId, super.key});

  /// The project whose records waiting for review are walked.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<List<String>> queue = ref.watch(
      reviewQueueProvider(projectId),
    );
    final ReviewPosition position = ref.watch(reviewCursorProvider(projectId));
    final ReviewCursor cursor = ref.read(
      reviewCursorProvider(projectId).notifier,
    );
    final List<String> ids = queue.value ?? const <String>[];
    final String? current = queue.hasValue ? position.currentIn(ids) : null;
    final bool busy =
        current != null && ref.watch(reviewControllerProvider(current)).busy;
    return AppPage(
      key: const ValueKey<String>('route-batch-review'),
      title: localCopy.reviewTitle,
      subtitle: current == null
          ? null
          : localCopy.reviewPosition(ids.indexOf(current) + 1, ids.length),
      overflow: <AppOverflowAction>[
        if (queue.hasValue && position.canGoBack(ids))
          AppOverflowAction(
            key: const ValueKey<String>('batch-back'),
            label: localCopy.reviewPreviousRecord,
            icon: AppIcons.back,
            onTap: () => cursor.back(ids),
          ),
      ],
      footer: current == null
          ? null
          : ResponsivePair(
              start: AppButton(
                key: const ValueKey<String>('batch-skip'),
                label: localCopy.reviewSkip,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: busy ? null : () => cursor.skip(ids),
              ),
              end: AppPrimaryAction(
                key: const ValueKey<String>('batch-approve'),
                label: localCopy.reviewApproveNext,
                busy: busy,
                onPressed: () =>
                    unawaited(_approve(context, ref, current, ids, cursor)),
              ),
            ),
      body: AsyncValueView<List<String>>(
        value: queue,
        loadingShape: SkeletonShape.detail,
        loadingCount: 1,
        isEmpty: (List<String> loaded) =>
            loaded.isEmpty || position.currentIn(loaded) == null,
        empty: () => position.done
            ? AppEmptyState(
                icon: AppIcons.verified,
                headline: Copy.of(context).reviewQueueDone,
                message: Copy.of(context).reviewQueueDoneMessage,
                actionLabel: Copy.of(context).reviewBackToRecords,
                onAction: () => _toRecords(context),
              )
            : AppEmptyState(
                icon: AppIcons.review,
                headline: Copy.of(context).reviewQueueEmpty,
                message: Copy.of(context).reviewEmptyMessage,
                actionLabel: Copy.of(context).reviewBackToRecords,
                onAction: () => _toRecords(context),
              ),
        onRetry: () => ref.invalidate(reviewQueueProvider(projectId)),
        data: (List<String> loaded) => ReviewBody(
          key: ValueKey<String>('batch-record-${position.currentIn(loaded)}'),
          projectId: projectId,
          recordId: position.currentIn(loaded)!,
          onBackToRecords: () => _toRecords(context),
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    String recordId,
    List<String> ids,
    ReviewCursor cursor,
  ) async {
    final Result<ApprovalOutcome> result = await ref
        .read(reviewControllerProvider(recordId).notifier)
        .approve(ids);
    if (!context.mounted) {
      return;
    }
    final ApprovalOutcome? outcome = ReviewApproval.report(context, result);
    if (outcome is Approved) {
      cursor.approved(outcome.nextRecordId);
    }
  }

  void _toRecords(BuildContext context) {
    context.go(RoutePaths.projectRecords(projectId));
  }
}
