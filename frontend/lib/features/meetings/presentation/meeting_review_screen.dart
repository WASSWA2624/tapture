import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/security/untrusted_text.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/review/review.dart' show ReviewApproval;

import '../domain/meeting.dart';
import '../domain/meeting_repository.dart';
import '../domain/meeting_transcription.dart';
import 'meeting_live_section.dart';
import 'meeting_review_providers.dart';

/// Meeting summary in front of the same approve action as any other record.
///
/// An action with no owner or due date blocks approval when the template
/// requires them, and the block names that action.
final class MeetingReviewScreen extends ConsumerWidget {
  /// Creates the review. A null [meeting] is read by [meetingId]; with
  /// neither it is the empty state. With [meetingId] the page records the
  /// meeting live above the review, on project [projectId] (the meeting's
  /// own project when null).
  const MeetingReviewScreen({
    this.meeting,
    this.meetingId,
    this.projectId,
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

  /// The meeting to read when [meeting] is not given, and to record.
  final String? meetingId;

  /// The project the meeting is filed on.
  final String? projectId;

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
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: localCopy.meetingReviewTitle,
        body: AppErrorState(failure: failed),
      );
    }
    final Meeting? given = meeting;
    final String? id = meetingId;
    if (given != null) {
      return _review(
        context,
        ref,
        given,
        notes: notes,
        minutes: minutes,
        transcript: transcript,
        versions: const <TranscriptVersion>[],
      );
    }
    if (id == null) {
      return _empty(localCopy);
    }
    return ref
        .watch(meetingRecordProvider(id))
        .when(
          data: (MeetingRecord? record) => record == null
              ? _empty(localCopy)
              : _review(
                  context,
                  ref,
                  record.meeting,
                  notes: record.notes,
                  minutes: record.minutes,
                  transcript: record.transcript,
                  versions: record.transcripts,
                ),
          error: (Object error, StackTrace _) => AppPage(
            title: localCopy.meetingReviewTitle,
            body: AppErrorState(failure: Failure.from(error)),
          ),
          loading: () => AppPage(
            title: localCopy.meetingReviewTitle,
            body: const AppSkeleton(shape: SkeletonShape.detail, count: 1),
          ),
        );
  }

  Widget _empty(LocalizedCopy localCopy) {
    return AppPage(
      title: localCopy.meetingReviewTitle,
      body: AppEmptyState(
        icon: AppIcons.review,
        headline: localCopy.meetingReviewEmpty,
        message: localCopy.meetingReviewEmptyMessage,
      ),
    );
  }

  Widget _review(
    BuildContext context,
    WidgetRef ref,
    Meeting loaded, {
    required String notes,
    required String minutes,
    required String transcript,
    required List<TranscriptVersion> versions,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);
    final String? recording = meetingId;
    final String project = projectId ?? loaded.projectId;
    final List<String> blocks = loaded.exportBlocks(
      requireOwner: requireActionDetails,
    );
    final Widget notesPane = AppTextField(
      key: const ValueKey<String>('meeting-notes'),
      label: localCopy.meetingNotes,
      controller: TextEditingController(text: notes),
      onChanged: onNotes,
    );
    final Widget minutesPane = AppTextField(
      key: const ValueKey<String>('meeting-minutes'),
      label: localCopy.meetingMinutes,
      controller: TextEditingController(text: minutes),
      onChanged: onMinutes,
    );
    final bool expanded = context.sizeClass == SizeClass.expanded;
    return AppPage(
      key: const ValueKey<String>('route-meeting-review'),
      title: localCopy.meetingReviewTitle,
      footer: AppButton(
        key: const ValueKey<String>('meeting-approve'),
        label: localCopy.meetingApprove,
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
          if (recording != null && project.isNotEmpty) ...<Widget>[
            MeetingLiveSection(
              meetingId: recording,
              projectId: project,
              versions: versions,
            ),
            const SizedBox(height: Space.x4),
          ],
          Text(
            localCopy.meetingAttendanceCount(loaded.attendanceCount),
            key: const ValueKey<String>('meeting-attendance-count'),
          ),
          Text('${loaded.decisions.length}'),
          Text('${loaded.actions.length}'),
          if (blocks.isNotEmpty)
            Text(
              localCopy.meetingActionBlocked(blocks.first),
              key: const ValueKey<String>('meeting-approval-block'),
            ),
          if (transcript.isNotEmpty)
            // A transcript is outside text: shown as captured, never read.
            Text(
              UntrustedText(transcript).forDisplay(),
              key: const ValueKey<String>('meeting-transcript'),
            ),
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
