import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import '../domain/meeting_transcription.dart';

/// Elapsed time and free space while a recording is open, and the file that
/// remains when recording is interrupted.
final class MeetingAudioSection extends StatelessWidget {
  /// Creates the section. Idle with no file is the empty state.
  const MeetingAudioSection({
    this.elapsed = Duration.zero,
    this.remainingLabel = '',
    this.recording = false,
    this.partialPath,
    this.versions = const <TranscriptVersion>[],
    this.failure,
    this.onStart,
    this.onStop,
    super.key,
  });

  /// Time recorded so far.
  final Duration elapsed;

  /// Free space, already labelled for display.
  final String remainingLabel;

  /// Whether a take is in progress.
  final bool recording;

  /// Partial file kept after an interruption. It stays attached.
  final String? partialPath;

  /// Transcription runs. A later run is another version.
  final List<TranscriptVersion> versions;

  /// Why recording could not start.
  final Failure? failure;

  /// Starts a take.
  final VoidCallback? onStart;

  /// Stops a take.
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final String? partial = partialPath;
    if (!recording && partial == null && versions.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.recordAudio,
        headline: localCopy.meetingRecordingEmpty,
        message: localCopy.meetingRecordingEmptyMessage,
        actionLabel: localCopy.meetingRecord,
        onAction: onStart,
      );
    }
    final String clock = _clock(elapsed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          localCopy.meetingElapsed(clock),
          key: const ValueKey<String>('audio-elapsed'),
        ),
        if (remainingLabel.isNotEmpty)
          Text(
            localCopy.meetingRemaining(remainingLabel),
            key: const ValueKey<String>('audio-remaining'),
          ),
        if (recording)
          AppButton(
            key: const ValueKey<String>('audio-stop'),
            label: localCopy.meetingStop,
            onPressed: onStop,
          ),
        if (partial != null)
          Text(
            '${localCopy.meetingInterrupted} $partial',
            key: const ValueKey<String>('audio-partial'),
          ),
        for (final TranscriptVersion version in versions)
          Text(
            version.text,
            key: ValueKey<String>('audio-version-${version.version}'),
          ),
      ],
    );
  }

  static String _clock(Duration elapsed) {
    final int minutes = elapsed.inMinutes;
    final int seconds = elapsed.inSeconds.remainder(60);
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
