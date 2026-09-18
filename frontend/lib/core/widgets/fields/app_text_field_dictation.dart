part of 'app_text_field.dart';

/// Microphone glue for [AppTextField]: when to offer it, and where the
/// words it hears land.
extension _FieldDictation on _AppTextFieldState {
  /// Whether this field ends in a microphone.
  bool get _offersDictation {
    final AppTextField field = widget;
    final DictationScope? scope = DictationScope.maybeOf(context);
    return scope != null &&
        scope.service.isSupported &&
        field.dictation &&
        field.enabled &&
        !field.readOnly &&
        !field.obscureText &&
        _speakable(field.keyboardType);
  }

  void _toggleDictation() {
    final DictationScope? scope = DictationScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    if (!_dictation.isActive) {
      // A new listen places its words at the caret, not over the last one's.
      _spokenFrom = null;
      _spokenTo = null;
      _lastSpoken = '';
      _keptWords = 0;
    }
    _dictation.toggle(
      scope.service,
      languageTag: scope.languageTag,
      onDeviceOnly: scope.onDeviceOnly,
    );
  }

  /// Puts [spoken] in the field: replacing the words this listen already
  /// put there, or at the caret. Results arrive whole each time, so words
  /// the operator kept by typing mid-listen are skipped.
  void _insertSpoken(String spoken, {required bool isFinal}) {
    if (!mounted) {
      return;
    }
    _lastSpoken = spoken;
    final String words = _keptWords == 0
        ? spoken
        : spoken.trim().split(_spaces).skip(_keptWords).join(' ');
    if (isFinal) {
      _keptWords = 0;
    }
    if (words.trim().isEmpty && _spokenFrom == null) {
      return;
    }
    final AppTextField field = widget;
    final TextEditingValue value = field.controller.value;
    int from;
    int to;
    if (_spokenFrom != null && _spokenTo != null) {
      from = _spokenFrom!.clamp(0, value.text.length);
      to = _spokenTo!.clamp(from, value.text.length);
    } else {
      final TextSelection selection = value.selection;
      from = selection.isValid ? selection.start : value.text.length;
      to = selection.isValid ? selection.end : from;
      if (from > to) {
        final int swap = from;
        from = to;
        to = swap;
      }
      _spokenFrom = from;
    }
    final ({String text, int caret}) next = SpokenText.insert(
      text: value.text,
      spoken: words,
      start: from,
      end: to,
      sentences: isFinal && (field.maxLines ?? 1) > 1,
      maxLength: field.maxLength,
      languageTag: DictationScope.maybeOf(context)?.languageTag ?? 'en',
    );
    _applyingSpoken = true;
    field.controller.value = TextEditingValue(
      text: next.text,
      selection: TextSelection.collapsed(offset: next.caret),
    );
    _applyingSpoken = false;
    _spokenTo = next.caret;
    if (isFinal) {
      _spokenFrom = null;
      _spokenTo = null;
    }
    if (next.text != value.text) {
      field.onChanged?.call(next.text);
    }
  }

  void _explain(Failure failure) {
    if (!mounted || ScaffoldMessenger.maybeOf(context) == null) {
      return;
    }
    showAppSnack(context, failure.message, tone: SnackTone.warning);
  }
}

final RegExp _spaces = RegExp(r'\s+');

int _wordCount(String text) {
  final String trimmed = text.trim();
  return trimmed.isEmpty ? 0 : trimmed.split(_spaces).length;
}

/// Free text a person would say: not numbers, dates, e-mail, links or phone
/// numbers, which a recogniser writes out as words.
bool _speakable(TextInputType? type) {
  return type == null ||
      type == TextInputType.text ||
      type == TextInputType.multiline ||
      type == TextInputType.name;
}
