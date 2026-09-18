/// Tidies what a recogniser heard and fits it into text already typed.
///
/// Recognisers hand back words with stray spacing, no capitals and no
/// closing stop. This makes a dictated run read as if it had been typed,
/// and only ever touches the words just spoken: what the operator already
/// wrote is never rewritten.
abstract final class SpokenText {
  /// [raw] with its spacing, punctuation spacing and capitals tidied.
  ///
  /// With [sentences], every sentence opens with a capital and the run ends
  /// with a full stop unless it already ends in punctuation. Without it, the
  /// run is left as a phrase: a name, a type or a search term.
  static String tidy(
    String raw, {
    bool sentences = true,
    String languageTag = 'en',
  }) {
    return _tidy(raw, sentences, languageTag, opensSentence: sentences);
  }

  /// Where [spoken] lands in [text] at [start]..[end], and the caret after it.
  ///
  /// Spacing is added on either side only where the neighbours need it. A
  /// run that starts a sentence (at the start, or after a stop or a new
  /// line) opens with a capital; one that closes the text ends with a stop
  /// when [sentences] is on. [maxLength], when given, is never exceeded: the
  /// run is cut at a word boundary to fit.
  static ({String text, int caret}) insert({
    required String text,
    required String spoken,
    int? start,
    int? end,
    bool sentences = true,
    int? maxLength,
    String languageTag = 'en',
  }) {
    final int from = _clamp(start ?? text.length, text.length);
    final int to = _clamp(end ?? from, text.length);
    final String before = text.substring(0, from < to ? from : to);
    final String after = text.substring(from < to ? to : from);
    final bool atEnd = after.trim().isEmpty;
    final bool opensSentence = before.trim().isEmpty || _endsSentence(before);
    String run = _tidy(
      spoken,
      sentences && atEnd,
      languageTag,
      opensSentence: sentences && opensSentence,
    );
    if (run.isEmpty) {
      return (text: text, caret: before.length);
    }
    if (sentences && opensSentence) {
      run = _capitalise(run);
    } else if (sentences && !atEnd) {
      run = run.replaceAll(_trailingStop, '');
    }
    final String lead = before.isEmpty || _endsInSpace(before) ? '' : ' ';
    final String trail = after.isEmpty || _startsTight(after) ? '' : ' ';
    final int? max = maxLength;
    if (max != null) {
      final int room = max - before.length - after.length;
      final int fixed = lead.length + trail.length;
      if (room <= fixed) {
        return (text: text, caret: before.length);
      }
      run = _fit(run, room - fixed);
      if (run.isEmpty) {
        return (text: text, caret: before.length);
      }
    }
    final String head = '$before$lead$run';
    return (text: '$head$trail$after', caret: head.length);
  }
}

/// [tidy], capitalising the first word only when it [opensSentence].
String _tidy(
  String raw,
  bool sentences,
  String languageTag, {
  required bool opensSentence,
}) {
  String text = raw.replaceAll(_whitespace, ' ').trim();
  if (text.isEmpty) {
    return '';
  }
  text = text
      .replaceAllMapped(_spaceBeforeMark, (Match m) => m[1]!)
      .replaceAllMapped(_repeatedMark, (Match m) => m[1]!)
      .replaceAllMapped(_markBeforeLetter, (Match m) => '${m[1]} ${m[2]}');
  if (_isEnglish(languageTag)) {
    text = text.replaceAllMapped(_loneI, (Match m) => 'I${m[1] ?? ''}');
  }
  if (!sentences) {
    return text;
  }
  text = text.replaceAllMapped(
    _sentenceStart,
    (Match m) => '${m[1]}${m[2]!.toUpperCase()}',
  );
  if (!_closingMarks.contains(text[text.length - 1])) {
    text = '$text.';
  }
  return opensSentence ? _capitalise(text) : text;
}

/// Any run of whitespace, including new lines a recogniser emits.
final RegExp _whitespace = RegExp(r'\s+');

/// A space a recogniser left before closing punctuation: `word ,`.
final RegExp _spaceBeforeMark = RegExp(r'\s+([,.;:!?])');

/// The same mark twice: `,,` or `..`. Ellipses are rare in dictation.
final RegExp _repeatedMark = RegExp(r'([,.;:!?])\1+');

/// Punctuation glued to the next word: `stop.then`. Digits are left alone
/// so `3.5` and `10:30` survive.
final RegExp _markBeforeLetter = RegExp(r'([,.;:!?])(\p{L})', unicode: true);

/// English lower-case `i` standing alone, or before `'m`, `'ve`, `'ll`, `'d`.
final RegExp _loneI = RegExp(r"\bi\b('(?:m|ve|ll|d))?");

/// A letter that follows a sentence end inside the run.
final RegExp _sentenceStart = RegExp(r'([.!?]\s+)(\p{Ll})', unicode: true);

/// Marks a sentence may already end with.
const String _closingMarks = '.!?,;:';

/// A closing stop, dropped when the run lands mid-sentence.
final RegExp _trailingStop = RegExp(r'[.]$');

bool _isEnglish(String languageTag) {
  final String language = languageTag.split(RegExp('[-_]')).first;
  return language.toLowerCase() == 'en';
}

String _capitalise(String text) {
  if (text.isEmpty) {
    return text;
  }
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

bool _endsSentence(String before) {
  final String trimmed = before.trimRight();
  if (trimmed.isEmpty) {
    return true;
  }
  if (before.endsWith('\n')) {
    return true;
  }
  return '.!?'.contains(trimmed[trimmed.length - 1]);
}

bool _endsInSpace(String before) {
  return before.endsWith(' ') || before.endsWith('\n');
}

/// Whether [after] starts with a space, a new line or closing punctuation,
/// so no space is needed between the run and it.
bool _startsTight(String after) {
  return ' \n,.;:!?)'.contains(after[0]);
}

int _clamp(int value, int length) {
  if (value < 0) {
    return length;
  }
  return value > length ? length : value;
}

/// [run] cut to [room] characters at the last word boundary that fits.
String _fit(String run, int room) {
  if (run.length <= room) {
    return run;
  }
  final String cut = run.substring(0, room);
  if (run[room] == ' ') {
    return cut.trimRight();
  }
  final int space = cut.lastIndexOf(' ');
  return (space > 0 ? cut.substring(0, space) : cut).trimRight();
}
