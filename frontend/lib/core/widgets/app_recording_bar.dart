import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_recording_phase.dart';

/// The one recording control row: status, elapsed time, input level and the
/// controls the [phase] allows (FE-CONS-01).
///
/// The status is a live region, so a screen reader hears each change of
/// phase; the clock is not announced, so it does not chatter. Status and
/// controls wrap onto separate rows when the width or text scale needs it.
///
/// Start, pause, resume and discard appear only when their callback is set.
/// Stop is always shown while a recording is open: disabled without
/// [onStop], and busy while the microphone opens or the recording closes.
class AppRecordingBar extends StatelessWidget {
  /// Creates a recording bar for [phase].
  const AppRecordingBar({
    required this.phase,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.status,
    this.startLabel,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onCancel,
    super.key,
  });

  /// Where the recording stands; decides the controls shown.
  final AppRecordingPhase phase;

  /// Time recorded so far, shown as `mm:ss`, or `h:mm:ss` past an hour.
  final Duration elapsed;

  /// Input level from 0 to 1. The caller holds it still while paused.
  final double level;

  /// Replaces the phase's own status, for a loading or background message.
  ///
  /// The status is a live region and is announced whenever it changes, so it
  /// should not carry a ticking value; the clock already shows the time.
  final String? status;

  /// Label of the start control. Defaults to the live transcript start.
  final String? startLabel;

  /// Starts a recording. Null hides the start control.
  final VoidCallback? onStart;

  /// Pauses the recording. Null hides the pause control.
  final VoidCallback? onPause;

  /// Resumes the recording. Null hides the resume control.
  final VoidCallback? onResume;

  /// Stops and keeps the recording. Null disables the stop control.
  final VoidCallback? onStop;

  /// Discards the recording. Null hides the discard control.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    final String? shown = status ?? _phaseStatus(localCopy);
    final bool open = phase != AppRecordingPhase.idle;
    final List<Widget> controls = _controls(localCopy);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Space.x4,
      runSpacing: Space.x2,
      children: <Widget>[
        if (shown != null || open)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: _meterWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (shown != null)
                  Semantics(
                    key: const ValueKey<String>('recording-bar-status'),
                    liveRegion: true,
                    child: Text(shown, style: AppText.bodyStrong),
                  ),
                if (open) ...<Widget>[
                  const SizedBox(height: Space.x1),
                  ExcludeSemantics(
                    child: Text(
                      _clock(elapsed),
                      key: const ValueKey<String>('recording-bar-clock'),
                      style: AppText.caption.copyWith(
                        color: context.colors.onSurfaceMuted,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.x1),
                  SizedBox(
                    width: _meterWidth,
                    child: ExcludeSemantics(
                      child: LinearProgressIndicator(
                        value: level.clamp(0.0, 1.0),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (controls.isNotEmpty)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: controls,
          ),
      ],
    );
  }

  String? _phaseStatus(LocalizedCopy localCopy) {
    return switch (phase) {
      AppRecordingPhase.idle => null,
      AppRecordingPhase.starting => localCopy.liveTranscriptStatusStarting,
      AppRecordingPhase.recording => localCopy.liveTranscriptStatusListening,
      AppRecordingPhase.paused => localCopy.liveTranscriptStatusPaused,
      AppRecordingPhase.finishing => localCopy.liveTranscriptStatusFinishing,
    };
  }

  List<Widget> _controls(LocalizedCopy localCopy) {
    final VoidCallback? start = onStart;
    final VoidCallback? pause = onPause;
    final VoidCallback? resume = onResume;
    final VoidCallback? cancel = onCancel;
    return switch (phase) {
      AppRecordingPhase.idle => <Widget>[
        if (start != null)
          _labelled(
            key: const ValueKey<String>('recording-bar-start'),
            label: startLabel ?? localCopy.liveTranscriptStart,
            icon: AppIcons.recordAudio,
            onPressed: start,
          ),
      ],
      AppRecordingPhase.starting ||
      AppRecordingPhase.finishing => <Widget>[_stop(localCopy, busy: true)],
      AppRecordingPhase.recording => <Widget>[
        if (pause != null)
          _labelled(
            key: const ValueKey<String>('recording-bar-pause'),
            label: localCopy.capturePauseAudio,
            icon: AppIcons.pause,
            variant: AppButtonVariant.secondary,
            onPressed: pause,
          ),
        _stop(localCopy, busy: false),
        if (cancel != null) _discard(localCopy, cancel),
      ],
      AppRecordingPhase.paused => <Widget>[
        if (resume != null)
          _labelled(
            key: const ValueKey<String>('recording-bar-resume'),
            label: localCopy.captureResume,
            icon: AppIcons.resume,
            variant: AppButtonVariant.secondary,
            onPressed: resume,
          ),
        _stop(localCopy, busy: false),
        if (cancel != null) _discard(localCopy, cancel),
      ],
    };
  }

  /// Stop carries no icon: the screen's own record toggle already shows the
  /// stop glyph, and one glyph names one control.
  Widget _stop(LocalizedCopy localCopy, {required bool busy}) {
    return _labelled(
      key: const ValueKey<String>('recording-bar-stop'),
      label: localCopy.captureStopAudio,
      busy: busy,
      onPressed: busy ? null : onStop,
    );
  }

  Widget _discard(LocalizedCopy localCopy, VoidCallback cancel) {
    return AppIconButton(
      key: const ValueKey<String>('recording-bar-discard'),
      icon: AppIcons.delete,
      semanticLabel: localCopy.liveTranscriptCancel,
      tooltip: localCopy.liveTranscriptCancel,
      onPressed: cancel,
    );
  }

  /// A labelled control with the same tooltip a pointer user gets on an
  /// icon control. The label already names it to assistive technology, so
  /// the tooltip is not announced a second time.
  Widget _labelled({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    AppButtonVariant variant = AppButtonVariant.primary,
    bool busy = false,
  }) {
    return Tooltip(
      key: key,
      message: label,
      excludeFromSemantics: true,
      child: AppButton(
        label: label,
        icon: icon,
        variant: variant,
        busy: busy,
        onPressed: onPressed,
      ),
    );
  }

  static String _clock(Duration elapsed) {
    final int hours = elapsed.inHours;
    final String minutes = elapsed.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final String seconds = elapsed.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  static const double _meterWidth = Space.x12 * 3;
}
