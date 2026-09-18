import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text_field.dart';

/// Phone entry built on [AppTextField]: a phone keyboard, telephone autofill,
/// digits and common punctuation only, no microphone. Validation stays
/// with the caller.
class AppPhoneField extends StatelessWidget {
  /// Creates a phone field. Optional by default; the caller passes [label]
  /// from catalogue copy.
  const AppPhoneField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.textInputAction,
    this.requiredness = FieldRequiredness.optional,
    this.onChanged,
    this.onSubmitted,
  });

  /// Visible label; also the semantic name of the control (FE-A11Y-02).
  final String label;

  /// Owns the text. The caller creates it so a size-class change cannot
  /// drop input (FE-RESP-03).
  final TextEditingController controller;

  /// Shared validation copy. This widget does not invent it.
  final String? errorText;

  /// When false, the field does not accept input.
  final bool enabled;

  /// IME action. Forms pass next or done.
  final TextInputAction? textInputAction;

  /// Whether the field is required, optional, or unmarked.
  final FieldRequiredness requiredness;

  /// Called on every accepted edit.
  final ValueChanged<String>? onChanged;

  /// Called when the IME submits.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      errorText: errorText,
      enabled: enabled,
      textInputAction: textInputAction,
      requiredness: requiredness,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: TextInputType.phone,
      autofillHints: const <String>[AutofillHints.telephoneNumber],
      inputFormatters: <TextInputFormatter>[_phoneCharacters],
      dictation: false,
    );
  }
}

/// Digits and the punctuation a phone number commonly carries. Letters
/// never land in the field; the caller still decides whether the value
/// is valid.
final TextInputFormatter _phoneCharacters = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9+().\s/-]'),
);
