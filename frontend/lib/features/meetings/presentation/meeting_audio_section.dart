import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/security/untrusted_text.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_recording_bar.dart';
import 'package:tapture/core/widgets/app_recording_phase.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show TranscriptSummary, TranscriptTile;

import '../domain/meeting_transcription.dart';

/// A meeting's recording: the recording bar, free space, the file kept
/// after an interruption, and one list of what was heard (FE-CONS-01).
///
/// The list holds the on-device transcripts first, which open, then the
/// older online transcription runs as read-only rows. Idle with nothing
/// recorded and no recorder given is the empty state.
final class MeetingAudioSection extends StatelessWidget {
  /// Creates the section. [recorder] replaces the recording bar, for a
  /// live transcript panel that has its own.
  const MeetingAudioSection({
    this.phase = AppRecordingPhase.idle,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.status,
    this.remainingLabel = '',
    this.partialPath,
    this.transcripts = const <TranscriptSummary>[],
    this.versions = const <TranscriptVersion>[],
    this.failure,
    this.recorder,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onCancel,
    this.onOpenTranscript,
    super.key,
  });

  /// Where the recording stands.
  final AppRecordingPhase phase;

  /// Time recorded so far.
  final Duration elapsed;

  /// Input level from 0 to 1.
  final double level;

  /// Replaces the phase's own status line, for a pause reason.
  final String? status;

  /// Free space, already labelled for display.
  final String remainingLabel;

  /// Partial file kept after an interruption. It stays attached.
  final String? partialPath;

  /// On-device transcripts of the meeting, newest first.
  final List<TranscriptSummary> transcripts;

  /// Older online transcription runs. Shown, never edited.
  final List<TranscriptVersion> versions;

  /// Why recording could not start.
  final Failure? failure;

  /// Shown in place of the recording bar, such as a live transcript panel.
  final Widget? recorder;

  /// Starts a take.
  final VoidCallback? onStart;

  /// Pauses a take.
  final VoidCallback? onPause;

  /// Resumes a paused take.
  final VoidCallback? onResume;

  /// Stops and keeps a take.
  final VoidCallback? onStop;

  /// Discards a take.
  final VoidCallback? onCancel;

  /// Opens an on-device transcript; without it the rows do not open.
  final ValueChanged<TranscriptSummary>? onOpenTranscript;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final String? partial = partialPath;
    final Widget? shownRecorder = recorder;
    final bool heard = transcripts.isNotEmpty || versions.isNotEmpty;
    if (shownRecorder == null &&
        phase == AppRecordingPhase.idle &&
        partial == null &&
        !heard) {
      return AppEmptyState(
        icon: AppIcons.recordAudio,
        headline: localCopy.meetingRecordingEmpty,
        message: localCopy.meetingRecordingEmptyMessage,
        actionLabel: localCopy.meetingRecord,
        onAction: onStart,
      );
    }
    final ValueChanged<TranscriptSummary>? open = onOpenTranscript;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        shownRecorder ??
            AppRecordingBar(
              phase: phase,
              elapsed: elapsed,
              level: level,
              status: status,
              startLabel: localCopy.meetingRecord,
              onStart: onStart,
              onPause: onPause,
              onResume: onResume,
              onStop: onStop,
              onCancel: onCancel,
            ),
        if (remainingLabel.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x2),
          Text(
            localCopy.meetingRemaining(remainingLabel),
            key: const ValueKey<String>('audio-remaining'),
          ),
        ],
        if (partial != null) ...<Widget>[
          const SizedBox(height: Space.x2),
          Text(
            '${localCopy.meetingInterrupted} $partial',
            key: const ValueKey<String>('audio-partial'),
          ),
        ],
        if (heard) ...<Widget>[
          const SizedBox(height: Space.x3),
          AppSectionHeader(title: localCopy.liveTranscriptListTitle),
          for (final TranscriptSummary transcript in transcripts)
            TranscriptTile(
              summary: transcript,
              onTap: open == null ? null : () => open(transcript),
            ),
          for (final TranscriptVersion version in versions)
            AppListTile(
              key: ValueKey<String>('audio-version-${version.version}'),
              leading: const Icon(AppIcons.transcript),
              title: localCopy.meetingTranscriptVersion(version.version),
              // Transcribed speech is outside text: shown, never read.
              subtitle: UntrustedText(version.text).forDisplay(),
              trailing: AppChip(label: localCopy.meetingTranscriptCloudVersion),
              wrapText: true,
            ),
        ],
      ],
    );
  }
}
