import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/speech/speech_text.dart';

import 'transcript_line.dart';

/// A transcript's lines grouped into paragraphs for reading.
///
/// A new paragraph starts after a pause of at least
/// `AppConstants.transcripts.paragraphGap`, or when the current one already
/// holds `paragraphMaxSegments` lines or would pass `paragraphMaxChars`
/// characters. A line with no words adds nothing. Growing a live transcript
/// one line at a time with [append] gives the same paragraphs as [group]
/// over the whole, and changes only the last paragraph or adds one.
final class TranscriptParagraphs {
  /// No paragraphs yet.
  const TranscriptParagraphs.empty()
    : paragraphs = const <String>[],
      _lastLines = 0,
      _previous = null;

  const TranscriptParagraphs._(this.paragraphs, this._lastLines, this._previous);

  /// The paragraphs of [lines], taken in the order given.
  static List<String> group(List<TranscriptLine> lines) {
    TranscriptParagraphs grouped = const TranscriptParagraphs.empty();
    for (final TranscriptLine line in lines) {
      grouped = grouped.append(line);
    }
    return grouped.paragraphs;
  }

  /// The paragraphs so far, in order. Never logged.
  final List<String> paragraphs;

  final int _lastLines;
  final TranscriptLine? _previous;

  /// These paragraphs with [next] added: to the last paragraph, or as the
  /// start of a new one.
  TranscriptParagraphs append(TranscriptLine next) {
    final String text = next.text.trim();
    if (text.isEmpty) {
      return TranscriptParagraphs._(paragraphs, _lastLines, next);
    }
    if (_startsParagraph(text, next)) {
      return TranscriptParagraphs._(<String>[...paragraphs, text], 1, next);
    }
    return TranscriptParagraphs._(
      <String>[
        ...paragraphs.take(paragraphs.length - 1),
        SpeechText.join(<String>[paragraphs.last, text]),
      ],
      _lastLines + 1,
      next,
    );
  }

  bool _startsParagraph(String text, TranscriptLine next) {
    final TranscriptLine? previous = _previous;
    if (paragraphs.isEmpty || previous == null) {
      return true;
    }
    return next.start - previous.end >= AppConstants.transcripts.paragraphGap ||
        _lastLines >= AppConstants.transcripts.paragraphMaxSegments ||
        paragraphs.last.length + 1 + text.length >
            AppConstants.transcripts.paragraphMaxChars;
  }
}
