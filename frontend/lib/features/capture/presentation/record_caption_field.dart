import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

/// Persist-as-you-type record caption.
final class RecordCaptionField extends StatefulWidget {
  /// Creates the field.
  const RecordCaptionField({
    required this.value,
    required this.onChanged,
    this.onWriteFailed,
    this.afterDictation,
    this.enabled = true,
    this.resetKey,
    super.key,
  });

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController(text: widget.value);
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
    _controller.dispose();
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
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (bool focused) => _focused = focused,
      child: AppTextField(
        controller: _controller,
        label: Copy.captureRecordCaption,
        minLines: 3,
        maxLines: 6,
        enabled: widget.enabled,
        textInputAction: TextInputAction.newline,
        onChanged: (String text) => _persist(text),
        afterDictation: widget.afterDictation,
      ),
    );
  }
}
