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
    _dictation.toggle(
      scope.service,
      languageTag: scope.languageTag,
      onDeviceOnly: scope.onDeviceOnly,
    );
  }

  void _insertSpoken(String spoken, {required bool isFinal}) {
    if (!mounted) {
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
      spoken: spoken,
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

/// Free text a person would say: not numbers, dates, e-mail, links or phone
/// numbers, which a recogniser writes out as words.
bool _speakable(TextInputType? type) {
  return type == null ||
      type == TextInputType.text ||
      type == TextInputType.multiline ||
      type == TextInputType.name;
}
