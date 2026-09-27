import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/records.dart';

import 'batch_review_screen.dart';
import 'review_approval.dart';

/// The project's review queue, one needs-review record at a time (task 016).
///
/// Skip, back and typed drafts stay here, so leaving a record and returning
/// shows the same text. Approving removes the record from the queue.
final class BatchReviewRoute extends ConsumerWidget {
  /// Creates the queue for [projectId].
  const BatchReviewRoute({required this.projectId, super.key});

  /// Project whose needs-review records are walked.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<String>> queue = ref.watch(
      _reviewQueueProvider(projectId),
    );
    return queue.when(
      loading: () => const AppPage(
        key: ValueKey<String>('route-batch-review'),
        title: Copy.reviewTitle,
        body: SizedBox.shrink(),
      ),
      error: (Object error, StackTrace _) => BatchReviewScreen(
        recordIds: const <String>[],
        index: 0,
        drafts: const <String, String>{},
        failure: Failure.from(error),
      ),
      data: (List<String> ids) {
        final _BatchCursor cursor = ref.watch(_batchCursorProvider(projectId));
        return BatchReviewScreen(
          recordIds: ids,
          index: cursor.index,
          drafts: cursor.drafts,
          onSkip: () =>
              ref.read(_batchCursorProvider(projectId).notifier).skip(),
          onBack: () =>
              ref.read(_batchCursorProvider(projectId).notifier).back(),
          onDraft: (String text) {
            if (cursor.index < 0 || cursor.index >= ids.length) {
              return;
            }
            ref
                .read(_batchCursorProvider(projectId).notifier)
                .draft(ids[cursor.index], text);
          },
          onApprove: () {
            if (cursor.index < 0 || cursor.index >= ids.length) {
              return;
            }
            unawaited(
              ReviewApproval.approve(
                context,
                ref,
                recordId: ids[cursor.index],
                queue: ids,
              ),
            );
          },
        );
      },
    );
  }
}

final _reviewQueueProvider = StreamProvider.autoDispose
    .family<List<String>, String>((Ref ref, String projectId) {
      return ref
          .watch(recordRepositoryProvider)
          .watchPage(
            projectId,
            filter: RecordFilter.forStatus(RecordStatus.needsReview),
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: AppConstants.lists.pageSize,
          )
          .map(
            (List<RecordSummary> rows) => <String>[
              for (final RecordSummary row in rows) row.id,
            ],
          );
    }, retry: (int _, Object _) => null);

final _batchCursorProvider = NotifierProvider.autoDispose
    .family<_BatchCursorController, _BatchCursor, String>(
      _BatchCursorController.new,
      retry: (int _, Object _) => null,
    );

class _BatchCursor {
  const _BatchCursor({this.index = 0, this.drafts = const <String, String>{}});

  final int index;
  final Map<String, String> drafts;
}

class _BatchCursorController extends Notifier<_BatchCursor> {
  _BatchCursorController(this._projectId);

  // ignore: unused_field, the family key isolates one project's cursor
  final String _projectId;

  @override
  _BatchCursor build() => const _BatchCursor();

  /// Moves to the next record without approving.
  void skip() {
    state = _BatchCursor(index: state.index + 1, drafts: state.drafts);
  }

  /// Returns to the previous record.
  void back() {
    if (state.index == 0) {
      return;
    }
    state = _BatchCursor(index: state.index - 1, drafts: state.drafts);
  }

  /// Stores [text] against [id].
  void draft(String id, String text) {
    state = _BatchCursor(
      index: state.index,
      drafts: <String, String>{...state.drafts, id: text},
    );
  }
}
