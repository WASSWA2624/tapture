import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_transcript_view.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

import '../domain/transcript.dart';
import '../domain/transcript_paragraphs.dart';

/// A transcript's text, edited beside the original (spec §30.4.6): the
/// operator's edit in a field, and the raw text, as it was heard, in
/// paragraphs that are never changed.
///
/// The field starts from what the transcript reads as. It follows a write
/// that lands — a save, a revert, or a live transcript growing — and
/// reports every change through [onChanged], typed or dictated.
class TranscriptEditor extends StatefulWidget {
  /// An editor over [transcript]; [readOnly] while it is still recording
  /// or a write is in flight.
  const TranscriptEditor({
    required this.transcript,
    required this.onChanged,
    this.readOnly = false,
    super.key,
  });

  /// The transcript shown.
  final Transcript transcript;

  /// Told the field's text after every change. Never logged.
  final ValueChanged<String> onChanged;

  /// Whether the field refuses edits.
  final bool readOnly;

  @override
  State<TranscriptEditor> createState() => _TranscriptEditorState();
}

class _TranscriptEditorState extends State<TranscriptEditor> with StateRefresh {
  late final TextEditingController _text = TextEditingController(
    text: widget.transcript.displayText,
  );
  late String _reported = _text.text;
  bool _original = false;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
  }

  @override
  void didUpdateWidget(TranscriptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String shown = widget.transcript.displayText;
    if (shown != oldWidget.transcript.displayText && _text.text != shown) {
      // The stored text changed under the field: it is what the operator
      // sees now, and it is not an edit of theirs.
      _following = true;
      _text.text = shown;
      _reported = shown;
      _following = false;
    }
  }

  @override
  void dispose() {
    _text
      ..removeListener(_onText)
      ..dispose();
    super.dispose();
  }

  void _onText() {
    final String text = _text.text;
    if (_following || text == _reported) {
      return;
    }
    _reported = text;
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppChipRow(
          chips: <AppChip>[
            AppChip(
              key: const ValueKey<String>('transcript-show-edited'),
              label: localCopy.transcriptEditedLabel,
              selected: !_original,
              onTap: () => refresh(() => _original = false),
            ),
            AppChip(
              key: const ValueKey<String>('transcript-show-original'),
              label: localCopy.transcriptOriginalLabel,
              selected: _original,
              onTap: () => refresh(() => _original = true),
            ),
          ],
        ),
        const SizedBox(height: Space.x3),
        if (_original)
          AppTranscriptView(
            key: const ValueKey<String>('transcript-original'),
            paragraphs: TranscriptParagraphs.group(widget.transcript.lines),
          )
        else
          AppTextField(
            key: const ValueKey<String>('transcript-edited'),
            label: localCopy.transcriptEditedLabel,
            controller: _text,
            minLines: _minLines,
            maxLines: null,
            readOnly: widget.readOnly,
            keyboardType: TextInputType.multiline,
          ),
      ],
    );
  }

  /// Rows the field opens with, so a short transcript still reads as text
  /// to edit.
  static const int _minLines = 8;
}
