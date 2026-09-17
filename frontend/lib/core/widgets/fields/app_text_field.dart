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
class AppTextField extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final int lines = maxLines ?? 1;
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
          child: TextField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            maxLines: lines,
            minLines: lines > 1 ? lines : null,
            maxLength: maxLength,
            keyboardType:
                keyboardType ??
                (lines > 1 ? TextInputType.multiline : TextInputType.text),
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: onTap,
            style: AppText.body.copyWith(color: context.colors.onSurface),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              helperText: helper,
              errorText: errorText,
              alignLabelWithHint: lines > 1,
              prefixIcon: prefix,
              prefixIconConstraints: const BoxConstraints(
                minWidth: Sizes.minTapTarget,
                minHeight: Sizes.minTapTarget,
              ),
              suffixIcon: _suffix(context),
              suffixIconConstraints: const BoxConstraints(
                minWidth: Sizes.minTapTarget,
                minHeight: Sizes.minTapTarget,
              ),
              counter: maxLength == null
                  ? null
                  : Text(
                      _counterLabel(
                        context,
                        controller.text.length,
                        maxLength!,
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

  Widget? _suffix(BuildContext context) {
    final bool showClear =
        clearable && enabled && !readOnly && controller.text.isNotEmpty;
    if (!showClear && trailing == null) {
      return null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showClear)
          AppIconButton(
            icon: Icons.clear,
            semanticLabel: Copy.clearField(label),
            tooltip: Copy.clearField(label),
            onPressed: () {
              controller.clear();
              onChanged?.call('');
            },
          ),
        ?trailing,
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
