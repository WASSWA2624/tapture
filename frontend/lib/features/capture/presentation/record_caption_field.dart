import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

/// Persist-as-you-type record caption. With a [guide], a small panel above
/// the field lists what the caption should cover while the field has focus,
/// dictation runs or [recorder] records (FBK0000159, D14). It never takes
/// focus and never covers the field.
final class RecordCaptionField extends StatefulWidget {
  /// Creates the field.
  const RecordCaptionField({
    required this.value,
    required this.onChanged,
    this.onWriteFailed,
    this.afterDictation,
    this.enabled = true,
    this.resetKey,
    this.guide = const <String>[],
    this.onCloseGuide,
    this.recorder,
    super.key,
  });

  /// What the caption should cover, as template field labels; empty shows
  /// no panel.
  final List<String> guide;

  /// Hides the panel; shows its close control when set.
  final VoidCallback? onCloseGuide;

  /// The audio recorder whose recording also shows the panel.
  final AudioRecorderService? recorder;

  /// Current caption.
  final String value;

  /// Persist callback (async write).
  final Future<bool> Function(String text) onChanged;

  /// Optional failure handler.
  final ValueChanged<String>? onWriteFailed;

  /// Control drawn after the speech-to-text microphone.
  final Widget? afterDictation;

  /// When false, the field and its microphone do not accept input.
  final bool enabled;

  /// Changes when the caption is replaced from outside; [value] then
  /// replaces the typed text. Otherwise [value] replaces it only while the
  /// field is not being typed in, so a late save never resets typing
  /// (FBK0000149).
  final Object? resetKey;

  @override
  State<RecordCaptionField> createState() => _RecordCaptionFieldState();
}

class _RecordCaptionFieldState extends State<RecordCaptionField>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
  bool _focused = false;
  final ValueNotifier<bool> _typing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _dictating = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _recording = ValueNotifier<bool>(false);
  StreamSubscription<AudioRecorderState>? _recorder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController(text: widget.value);
    _recorder = widget.recorder?.state.listen((AudioRecorderState next) {
      _recording.value =
          next.phase == AudioRecorderPhase.recording ||
          next.phase == AudioRecorderPhase.paused;
    });
  }

  @override
  void didUpdateWidget(covariant RecordCaptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) {
      return;
    }
    final bool reset = oldWidget.resetKey != widget.resetKey;
    if (reset || (!_focused && oldWidget.value != widget.value)) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_recorder?.cancel());
    _controller.dispose();
    _typing.dispose();
    _dictating.dispose();
    _recording.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _persist(_controller.text);
    }
  }

  Future<void> _persist(String text) async {
    final bool ok = await widget.onChanged(text);
    if (!ok) {
      widget.onWriteFailed?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[
            _typing,
            _dictating,
            _recording,
          ]),
          builder: (BuildContext context, Widget? _) {
            final bool active =
                _typing.value || _dictating.value || _recording.value;
            if (!active || widget.guide.isEmpty) {
              return const SizedBox.shrink();
            }
            return _CaptionGuidePanel(
              labels: widget.guide,
              onClose: widget.onCloseGuide,
            );
          },
        ),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (bool focused) {
            _focused = focused;
            _typing.value = focused;
          },
          child: AppTextField(
            controller: _controller,
            label: localCopy.captureRecordCaption,
            minLines: 3,
            maxLines: 6,
            enabled: widget.enabled,
            textInputAction: TextInputAction.newline,
            onChanged: (String text) => _persist(text),
            onDictationChanged: (bool active) => _dictating.value = active,
            afterDictation: widget.afterDictation,
          ),
        ),
      ],
    );
  }
}

/// What the caption should cover, above the field while a person types,
/// dictates or records. Announced once as it appears (FE-A11Y-07).
class _CaptionGuidePanel extends StatelessWidget {
  const _CaptionGuidePanel({required this.labels, required this.onClose});

  final List<String> labels;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    final VoidCallback? close = onClose;
    return Padding(
      key: const ValueKey<String>('capture-caption-guide'),
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              Space.x3,
              Space.x2,
              Space.x1,
              Space.x2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        localCopy.captureGuideCaption,
                        style: AppText.label.copyWith(color: colors.onSurface),
                      ),
                      Text(
                        localCopy.captureGuideItems(labels),
                        style: AppText.body.copyWith(color: colors.onSurface),
                      ),
                    ],
                  ),
                ),
                if (close != null)
                  AppIconButton(
                    key: const ValueKey<String>('capture-caption-guide-close'),
                    icon: AppIcons.close,
                    tooltip: localCopy.captureGuideClose,
                    semanticLabel: localCopy.captureGuideClose,
                    outlined: false,
                    onPressed: close,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
