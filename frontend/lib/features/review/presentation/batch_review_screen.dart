import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// One record at a time through a filtered review set (task 016).
///
/// Skip and back keep [drafts], so returning to a record shows what was typed.
final class BatchReviewScreen extends StatelessWidget {
  /// Creates the queue.
  const BatchReviewScreen({
    required this.recordIds,
    required this.index,
    required this.drafts,
    this.failure,
    this.onSkip,
    this.onBack,
    this.onDraft,
    this.onApprove,
    super.key,
  });

  /// The filtered record ids, in review order.
  final List<String> recordIds;

  /// The record currently shown, from 0.
  final int index;

  /// Typed text kept per record id.
  final Map<String, String> drafts;

  /// Why the queue could not be read.
  final Failure? failure;

  /// Moves to the next record without approving.
  final VoidCallback? onSkip;

  /// Returns to the previous record.
  final VoidCallback? onBack;

  /// Stores the draft for the current record.
  final ValueChanged<String>? onDraft;

  /// Approves and moves on.
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        key: const ValueKey<String>('route-batch-review'),
        title: Copy.reviewTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (recordIds.isEmpty) {
      return const AppPage(
        key: ValueKey<String>('route-batch-review'),
        title: Copy.reviewTitle,
        body: AppEmptyState(
          icon: AppIcons.review,
          headline: Copy.reviewQueueEmpty,
          message: Copy.reviewEmptyMessage,
        ),
      );
    }
    if (index < 0 || index >= recordIds.length) {
      return const AppPage(
        key: ValueKey<String>('route-batch-review'),
        title: Copy.reviewTitle,
        body: AppEmptyState(
          icon: AppIcons.verified,
          headline: Copy.reviewQueueDone,
          message: Copy.reviewQueueDoneMessage,
        ),
      );
    }
    final String id = recordIds[index];
    return AppPage(
      key: const ValueKey<String>('route-batch-review'),
      title: Copy.reviewTitle,
      subtitle: Copy.reviewPosition(index + 1, recordIds.length),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(id, key: const ValueKey<String>('batch-record')),
          AppTextField(
            key: ValueKey<String>('batch-draft-$id'),
            label: Copy.reviewTypeIt,
            controller: TextEditingController(text: drafts[id] ?? ''),
            onChanged: onDraft,
          ),
          AppButton(
            key: const ValueKey<String>('batch-back'),
            label: Copy.reviewBack,
            variant: AppButtonVariant.secondary,
            onPressed: index == 0 ? null : onBack,
          ),
          AppButton(
            key: const ValueKey<String>('batch-skip'),
            label: Copy.reviewSkip,
            variant: AppButtonVariant.secondary,
            onPressed: onSkip,
          ),
          AppButton(
            key: const ValueKey<String>('batch-approve'),
            label: Copy.reviewApproveNext,
            onPressed: onApprove,
          ),
        ],
      ),
    );
  }
}
