import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/review/review.dart' show ReviewApproval;

import '../domain/meeting.dart';

/// Meeting summary in front of the same approve action as any other record.
///
/// An action with no owner or due date blocks approval when the template
/// requires them, and the block names that action.
final class MeetingReviewScreen extends ConsumerWidget {
  /// Creates the review. A null [meeting] is the empty state.
  const MeetingReviewScreen({
    this.meeting,
    this.notes = '',
    this.minutes = '',
    this.transcript = '',
    this.requireActionDetails = false,
    this.failure,
    this.onApprove,
    this.onNotes,
    this.onMinutes,
    super.key,
  });

  /// The meeting being reviewed.
  final Meeting? meeting;

  /// Raw notes. Editable, and never replaced by refinement.
  final String notes;

  /// Refined minutes. Editable beside [notes].
  final String minutes;

  /// Verbatim transcript. Shown, not edited.
  final String transcript;

  /// When true, an action needs an owner and a due date.
  final bool requireActionDetails;

  /// Why the meeting could not be read.
  final Failure? failure;

  /// Approves through the record lifecycle.
  final VoidCallback? onApprove;

  /// Writes edited notes.
  final ValueChanged<String>? onNotes;

  /// Writes edited minutes. The transcript is not an argument.
  final ValueChanged<String>? onMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.meetingReviewTitle,
        body: AppErrorState(failure: failed),
      );
    }
    final Meeting? loaded = meeting;
    if (loaded == null) {
      return const AppPage(
        title: Copy.meetingReviewTitle,
        body: AppEmptyState(
          icon: AppIcons.review,
          headline: Copy.meetingReviewEmpty,
          message: Copy.meetingReviewEmptyMessage,
        ),
      );
    }
    final List<String> blocks = loaded.exportBlocks(
      requireOwner: requireActionDetails,
    );
    final Widget notesPane = AppTextField(
      key: const ValueKey<String>('meeting-notes'),
      label: Copy.meetingNotes,
      controller: TextEditingController(text: notes),
      onChanged: onNotes,
    );
    final Widget minutesPane = AppTextField(
      key: const ValueKey<String>('meeting-minutes'),
      label: Copy.meetingMinutes,
      controller: TextEditingController(text: minutes),
      onChanged: onMinutes,
    );
    final bool expanded = context.sizeClass == SizeClass.expanded;
    return AppPage(
      key: const ValueKey<String>('route-meeting-review'),
      title: Copy.meetingReviewTitle,
      footer: AppButton(
        key: const ValueKey<String>('meeting-approve'),
        label: Copy.meetingApprove,
        expand: true,
        onPressed: blocks.isEmpty
            ? () {
                final VoidCallback? approve = onApprove;
                if (approve != null) {
                  approve();
                  return;
                }
                final String? record = loaded.recordId;
                if (record == null) {
                  return;
                }
                unawaited(
                  ReviewApproval.approve(
                    context,
                    ref,
                    recordId: record,
                    queue: <String>[record],
                  ),
                );
              }
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            Copy.meetingAttendanceCount(loaded.attendanceCount),
            key: const ValueKey<String>('meeting-attendance-count'),
          ),
          Text('${loaded.decisions.length}'),
          Text('${loaded.actions.length}'),
          if (blocks.isNotEmpty)
            Text(
              Copy.meetingActionBlocked(blocks.first),
              key: const ValueKey<String>('meeting-approval-block'),
            ),
          if (transcript.isNotEmpty)
            Text(transcript, key: const ValueKey<String>('meeting-transcript')),
          if (expanded)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: notesPane),
                Expanded(child: minutesPane),
              ],
            )
          else ...<Widget>[notesPane, minutesPane],
        ],
      ),
    );
  }
}
