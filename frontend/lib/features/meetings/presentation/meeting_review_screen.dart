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
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/review/review.dart' show ReviewApproval;

import '../domain/meeting.dart';
import '../domain/meeting_transcription.dart';
import 'meeting_live_section.dart';
import 'meeting_review_controller.dart';
import 'meeting_text_field.dart';

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

  /// Working notes. Original source notes are preserved in the repository.
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
    if (given != null && id == null) {
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
        .watch(meetingReviewControllerProvider(id))
        .when(
          data: (MeetingReviewEdits? edits) {
            if (edits == null) {
              return _empty(localCopy);
            }
            final MeetingReviewController controller = ref.read(
              meetingReviewControllerProvider(id).notifier,
            );
            return _review(
              context,
              ref,
              edits.record.meeting,
              notes: edits.notes,
              minutes: edits.minutes,
              transcript: edits.record.transcript,
              versions: edits.record.transcripts,
              edits: edits,
              controller: controller,
            );
          },
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
    MeetingReviewEdits? edits,
    MeetingReviewController? controller,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);
    final String? recording = meetingId;
    final String project = projectId ?? loaded.projectId;
    final List<String> blocks = loaded.exportBlocks(
      requireOwner: requireActionDetails,
    );
    final Widget notesPane = MeetingTextField(
      key: const ValueKey<String>('meeting-notes'),
      label: localCopy.meetingNotes,
      value: notes,
      minLines: 4,
      maxLines: null,
      onChanged: controller?.editNotes ?? onNotes ?? _ignoreEdit,
    );
    final Widget minutesPane = MeetingTextField(
      key: const ValueKey<String>('meeting-minutes'),
      label: localCopy.meetingMinutes,
      value: minutes,
      minLines: 4,
      maxLines: null,
      onChanged: controller?.editMinutes ?? onMinutes ?? _ignoreEdit,
    );
    final bool expanded = context.sizeClass == SizeClass.expanded;
    return AppPage(
      key: const ValueKey<String>('route-meeting-review'),
      title: localCopy.meetingReviewTitle,
      footer: AppButton(
        key: const ValueKey<String>('meeting-approve'),
        label: localCopy.meetingApprove,
        expand: true,
        onPressed: blocks.isEmpty && !(edits?.dirty ?? false)
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
          AppSectionHeader(title: localCopy.meetingSummary),
          Text(
            localCopy.meetingAttendanceCount(loaded.attendanceCount),
            key: const ValueKey<String>('meeting-attendance-count'),
          ),
          Text(localCopy.meetingDecisionsCount(loaded.decisions.length)),
          Text(localCopy.meetingActionsCount(loaded.actions.length)),
          if (recording != null && project.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.x4),
            MeetingLiveSection(
              meetingId: recording,
              projectId: project,
              versions: versions,
            ),
          ],
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
          AppSectionHeader(title: localCopy.meetingNotesAndMinutes),
          if (edits?.failure case final Failure failure) ...<Widget>[
            AppBanner(
              message: localCopy.failureMessage(failure),
              icon: AppIcons.error,
              tone: SnackTone.error,
            ),
            AppButton(
              key: const ValueKey<String>('meeting-retry-save'),
              label: localCopy.save,
              variant: AppButtonVariant.secondary,
              onPressed: edits!.saving
                  ? null
                  : () => unawaited(controller!.flush()),
            ),
          ],
          if (edits?.saved ?? false)
            Semantics(liveRegion: true, child: Text(localCopy.recordEditSaved)),
          const SizedBox(height: Space.x2),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = expanded
                  ? (constraints.maxWidth - Space.x4) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: Space.x4,
                runSpacing: Space.x4,
                children: <Widget>[
                  SizedBox(width: width, child: notesPane),
                  SizedBox(width: width, child: minutesPane),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

void _ignoreEdit(String _) {}
