import 'package:flutter/material.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

/// A meeting text field bound to [value].
///
/// It owns its controller, so typing keeps the caret while the page
/// rebuilds, and it takes a new [value] only when that changes elsewhere,
/// such as refined minutes arriving.
final class MeetingTextField extends StatefulWidget {
  /// Creates the field showing [value].
  const MeetingTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.minLines,
    this.maxLines = 1,
    super.key,
  });

  /// Visible name of the field.
  final String label;

  /// The text as stored.
  final String value;

  /// Receives every edit.
  final ValueChanged<String> onChanged;

  /// Optional line under the field.
  final String? helper;

  /// Lines shown before any text.
  final int? minLines;

  /// Lines before the field scrolls; null grows with the text.
  final int? maxLines;

  @override
  State<MeetingTextField> createState() => _MeetingTextFieldState();
}

class _MeetingTextFieldState extends State<MeetingTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(MeetingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: _controller,
      helper: widget.helper,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
    );
  }
}
