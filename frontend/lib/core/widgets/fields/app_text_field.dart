import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';

/// The catalogue text input later fields and screens compose instead of a
/// raw [TextFormField].
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
    this.maxLength,
    this.prefix,
    this.trailing,
    this.clearable = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.autofocus = false,
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

  /// When set, a locale-formatted character counter is shown.
  final int? maxLength;

  /// Leading slot (search icon, unit, and similar).
  final Widget? prefix;

  /// Trailing slot for a microphone, scanner, or other action.
  final Widget? trailing;

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

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final AppTextField field = widget;
    final int lines = field.maxLines ?? 1;
    return ListenableBuilder(
      listenable: field.controller,
      builder: (BuildContext context, Widget? _) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
          child: TextField(
            controller: field.controller,
            enabled: field.enabled,
            readOnly: field.readOnly,
            maxLines: lines,
            minLines: lines > 1 ? lines : null,
            maxLength: field.maxLength,
            keyboardType:
                field.keyboardType ??
                (lines > 1 ? TextInputType.multiline : TextInputType.text),
            textInputAction: field.textInputAction,
            inputFormatters: field.inputFormatters,
            onChanged: field.onChanged,
            onSubmitted: field.onSubmitted,
            onTap: field.onTap,
            obscureText: field.obscureText && !_revealed,
            autofocus: field.autofocus,
            // Keyed to the field, not the toggle: revealing a secret must
            // not hand it to the keyboard's suggestions.
            enableSuggestions: !field.obscureText,
            autocorrect: !field.obscureText,
            style: AppText.body.copyWith(color: context.colors.onSurface),
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              helperText: field.helper,
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
                      style: AppText.caption.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget? _suffix(AppTextField field) {
    final bool showClear =
        field.clearable &&
        field.enabled &&
        !field.readOnly &&
        field.controller.text.isNotEmpty;
    if (!showClear && field.trailing == null && !field.obscureText) {
      return null;
    }
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
            onPressed: () {
              field.controller.clear();
              field.onChanged?.call('');
            },
          ),
        ?field.trailing,
        // Last, so the show / hide control is always the far end of the field.
        if (field.obscureText)
          AppIconButton(
            icon: _revealed
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            semanticLabel: reveal,
            tooltip: reveal,
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
