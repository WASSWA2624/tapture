import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/normalise/spoken_text.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import 'dictation_phase.dart';
import 'dictation_scope.dart';
import 'dictation_session.dart';

part 'app_text_field_dictation.dart';

/// The catalogue text input later fields and screens compose instead of a
/// raw [TextFormField].
///
/// Free-text fields end in a microphone when a [DictationScope] is above
/// them: the words heard are tidied and land at the caret, never
/// submitted. Secret, numeric, contact and read-only fields never offer it.
class AppTextField extends StatefulWidget {
  /// Creates a labelled text field. [errorText] is rendered, not decided,
  /// here — validation lives with the caller.
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefix,
    this.trailing,
    this.afterDictation,
    this.clearable = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.autofocus = false,
    this.dictation = true,
    this.requiredness = FieldRequiredness.unmarked,
  });

  /// Visible label; also the semantic name of the control (FE-A11Y-02).
  final String label;

  /// Owns the text. The caller creates it so a size-class change cannot
  /// drop input (FE-RESP-03).
  final TextEditingController controller;

  /// Empty-state prompt inside the field.
  final String? hint;

  /// Supporting line under the field. Hidden while [errorText] is set.
  final String? helper;

  /// Shared validation copy. This widget does not invent it.
  final String? errorText;

  /// Line count. `1` is a single line; larger values grow with the text.
  final int? maxLines;

  /// Starting height of a multiline field. Ignored when [maxLines] is `1`.
  final int? minLines;

  /// When set, a locale-formatted character counter is shown.
  final int? maxLength;

  /// Leading slot (search icon, unit, and similar).
  final Widget? prefix;

  /// Trailing slot placed before the microphone.
  final Widget? trailing;

  /// Trailing slot placed immediately after the microphone.
  final Widget? afterDictation;

  /// When true, a labelled clear control appears once the field has text.
  final bool clearable;

  /// When false, the field does not accept input.
  final bool enabled;

  /// When true, taps do not open the keyboard. Used by the date field.
  final bool readOnly;

  /// Keyboard type. Number and search fields pass theirs in.
  final TextInputType? keyboardType;

  /// IME action. Search passes [TextInputAction.search].
  final TextInputAction? textInputAction;

  /// Rejects characters as they are typed. Number fields pass a numeric
  /// formatter.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill hints. Email and phone pass theirs; omitted, the platform
  /// does not offer a saved value.
  final Iterable<String>? autofillHints;

  /// Called on every accepted edit.
  final ValueChanged<String>? onChanged;

  /// Called when the IME submits.
  final ValueChanged<String>? onSubmitted;

  /// Called on a tap. Date fields open a picker from here.
  final VoidCallback? onTap;

  /// Hides typed characters. PIN fields pass this so the secret is not
  /// shown on screen (FE-SEC-01). The field then ends in a show / hide
  /// control, and starts hidden whenever it first appears.
  final bool obscureText;

  /// Takes focus when first shown, so a single-field screen can be typed
  /// into at once.
  final bool autofocus;

  /// When false, no microphone is offered even where one would fit, for
  /// values nobody speaks, such as initials.
  final bool dictation;

  /// Whether the field is required, optional, or unmarked. Unmarked is the
  /// default so existing screens keep today's labels.
  final FieldRequiredness requiredness;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _revealed = false;
  int? _spokenFrom;
  int? _spokenTo;
  bool _applyingSpoken = false;
  String _lastSpoken = '';
  int _keptWords = 0;
  late final DictationSession _dictation = DictationSession(
    onSpoken: (String spoken) => _insertSpoken(spoken, isFinal: true),
    onPartial: (String spoken) => _insertSpoken(spoken, isFinal: false),
    onFailure: (Failure failure) => _explain(failure),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUserEdit);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onUserEdit);
      widget.controller.addListener(_onUserEdit);
      _spokenFrom = null;
      _spokenTo = null;
    }
    if (_dictation.isActive &&
        (oldWidget.controller != widget.controller || !_offersDictation)) {
      unawaited(_dictation.cancel());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUserEdit);
    // Cancels a listen still running, so leaving never keeps the microphone.
    _dictation.dispose();
    super.dispose();
  }

  /// Typing or moving the caret mid-listen keeps the words already in the
  /// field; later results only add what comes after them.
  void _onUserEdit() {
    if (_applyingSpoken) {
      return;
    }
    if (_spokenFrom != null) {
      _keptWords = _wordCount(_lastSpoken);
    }
    _spokenFrom = null;
    _spokenTo = null;
  }

  @override
  Widget build(BuildContext context) {
    final AppTextField field = widget;
    final int lines = field.maxLines ?? 1;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[field.controller, _dictation]),
      builder: (BuildContext context, Widget? _) {
        final Color onSurface = context.colors.onSurface;
        final ({String? text, Widget? widget, TextStyle? style}) support =
            _supportingCopy(field);
        Widget child = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
          child: TextField(
            controller: field.controller,
            enabled: field.enabled,
            readOnly: field.readOnly,
            maxLines: lines,
            minLines: field.minLines ?? (lines > 1 ? lines : null),
            maxLength: field.maxLength,
            keyboardType:
                field.keyboardType ??
                (lines > 1 ? TextInputType.multiline : TextInputType.text),
            textInputAction: field.textInputAction,
            inputFormatters: field.inputFormatters,
            autofillHints: field.autofillHints,
            onChanged: field.onChanged,
            onSubmitted: field.onSubmitted,
            onTap: field.onTap,
            textAlignVertical: lines > 1 ? TextAlignVertical.top : null,
            obscureText: field.obscureText && !_revealed,
            autofocus: field.autofocus,
            // Keyed to the field, not the toggle: revealing a secret must
            // not hand it to the keyboard's suggestions.
            enableSuggestions: !field.obscureText,
            autocorrect: !field.obscureText,
            style: AppText.body.copyWith(color: onSurface),
            decoration: InputDecoration(
              labelText: _labelText(field),
              hintText: field.hint,
              helperText: support.text,
              helper: support.widget,
              helperStyle: support.style,
              helperMaxLines: support.text == null && support.widget == null
                  ? null
                  : 3,
              errorText: field.errorText,
              alignLabelWithHint: lines > 1,
              prefixIcon: field.prefix,
              prefixIconConstraints: const BoxConstraints(
                minWidth: Sizes.minTapTarget,
                minHeight: Sizes.minTapTarget,
              ),
              suffixIcon: _suffix(field),
              suffixIconConstraints: const BoxConstraints(
                minWidth: Sizes.minTapTarget,
                minHeight: Sizes.minTapTarget,
              ),
              counter: field.maxLength == null
                  ? null
                  : Text(
                      _counterLabel(
                        context,
                        field.controller.text.length,
                        field.maxLength!,
                      ),
                      style: AppText.caption.copyWith(color: onSurface),
                    ),
            ),
          ),
        );
        if (field.requiredness != FieldRequiredness.unmarked) {
          child = Semantics(
            isRequired: field.requiredness == FieldRequiredness.required,
            child: child,
          );
        }
        return child;
      },
    );
  }

  Widget? _suffix(AppTextField field) {
    final bool showClear =
        field.clearable &&
        field.enabled &&
        !field.readOnly &&
        field.controller.text.isNotEmpty;
    final bool showMic = _offersDictation;
    if (!showClear &&
        field.trailing == null &&
        field.afterDictation == null &&
        !field.obscureText &&
        !showMic) {
      return null;
    }
    final bool on = _dictation.phase != DictationPhase.idle;
    final String mic = on
        ? Copy.stopDictating(field.label)
        : Copy.dictateInto(field.label);
    final String reveal = _revealed
        ? Copy.hideField(field.label)
        : Copy.showField(field.label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showClear)
          AppIconButton(
            icon: Icons.clear,
            semanticLabel: Copy.clearField(field.label),
            tooltip: Copy.clearField(field.label),
            outlined: false,
            onPressed: () {
              field.controller.clear();
              field.onChanged?.call('');
            },
          ),
        ?field.trailing,
        if (showMic)
          AppIconButton(
            key: const ValueKey<String>('app-text-field-dictate'),
            icon: on ? Icons.mic : Icons.mic_none,
            semanticLabel: mic,
            tooltip: mic,
            selected: on ? true : null,
            outlined: false,
            onPressed: () => _toggleDictation(),
          ),
        ?field.afterDictation,
        // Last, so the show / hide control is always the far end of the field.
        if (field.obscureText)
          AppIconButton(
            icon: _revealed
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            semanticLabel: reveal,
            tooltip: reveal,
            outlined: false,
            onPressed: () => setState(() => _revealed = !_revealed),
          ),
      ],
    );
  }
}

String _counterLabel(BuildContext context, int current, int max) {
  final NumberFormat format = NumberFormat.decimalPattern(_localeName(context));
  return '${format.format(current)} / ${format.format(max)}';
}

String _localeName(BuildContext context) {
  return Localizations.localeOf(context).toString();
}

String _labelText(AppTextField field) {
  return switch (field.requiredness) {
    FieldRequiredness.unmarked => field.label,
    FieldRequiredness.required => Copy.fieldLabelRequired(field.label),
    FieldRequiredness.optional => Copy.fieldLabelOptional(field.label),
  };
}

/// Helper copy only. Requiredness lives in the label (FE-L10N-03).
({String? text, Widget? widget, TextStyle? style}) _supportingCopy(
  AppTextField field,
) {
  return (text: field.helper, widget: null, style: null);
}

/// Whether an [AppTextField] is required, optional, or left unmarked.
enum FieldRequiredness {
  /// No requiredness caption. Existing screens stay as they are.
  unmarked,

  /// The field must be filled before Save.
  required,

  /// The field may be left empty.
  optional,
}
