import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show
        LiveTranscriptController,
        LiveTranscriptStatus,
        TranscriptSessionPhase,
        TranscriptSessionTarget,
        liveTranscriptControllerProvider;

/// The caption field's waveform control while a speech model is ready:
/// **Record and transcribe** starts a live transcript take of [target], and
/// Stop ends it once its audio is filed (task 125). What goes wrong shows
/// in the take's panel, which also pauses, resumes and discards it.
class CaptureTranscribeButton extends ConsumerWidget {
  /// The control for [target]'s take; [enabled] false takes no press.
  const CaptureTranscribeButton({
    required this.target,
    this.enabled = true,
    super.key,
  });

  /// The take this control starts and stops.
  final TranscriptSessionTarget target;

  /// When false, record and stop do not accept a press.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final LiveTranscriptStatus status = ref.watch(
      liveTranscriptControllerProvider(target.sessionKey),
    );
    final LiveTranscriptController controller = ref.read(
      liveTranscriptControllerProvider(target.sessionKey).notifier,
    );
    final TranscriptSessionPhase phase = status.phase;
    final bool open =
        phase == TranscriptSessionPhase.recording ||
        phase == TranscriptSessionPhase.paused;
    // A take whose filing failed is saved again from its panel, not
    // replaced by a new one.
    final bool busy =
        phase == TranscriptSessionPhase.starting ||
        phase == TranscriptSessionPhase.finishing ||
        (phase == TranscriptSessionPhase.failed && status.retryable);
    final String label = open
        ? localCopy.captureStopAudio
        : localCopy.captureRecordTranscribe;
    return AppIconButton(
      key: const ValueKey<String>('capture-record-audio'),
      icon: open ? AppIcons.stop : AppIcons.recordAudio,
      semanticLabel: label,
      tooltip: label,
      outlined: false,
      onPressed: enabled && !busy
          ? () => unawaited(open ? controller.stop() : controller.start(target))
          : null,
    );
  }
}
