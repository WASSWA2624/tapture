import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

import 'app_dialog.dart';

/// Collects a validated text value using the shared dialog and field.
Future<String?> showAppTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  required Future<Result<void>> Function(String value) validate,
  String initialValue = '',
  bool obscureText = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext _) => _TextPrompt(
      title: title,
      label: label,
      initialValue: initialValue,
      validate: validate,
      obscureText: obscureText,
    ),
  );
}

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.validate,
    required this.obscureText,
  });

  final bool obscureText;
  final String title;
  final String label;
  final String initialValue;
  final Future<Result<void>> Function(String) validate;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialValue,
  );
  LocalizedMessage? _error;
  bool _validating = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String value = _text.text;
    setState(() => _validating = true);
    final Result<void> result = await widget.validate(value);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<void>():
        Navigator.of(context).pop(value);
      case FailureResult<void>(:final failure):
        setState(() {
          _validating = false;
          _error = failure.explanation;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppDialog.confirm(
      title: widget.title,
      message: widget.label,
      confirmLabel: localCopy.save,
      confirmEnabled: !_validating,
      onConfirm: _save,
      onCancel: () => Navigator.of(context).pop(),
      extra: AppTextField(
        label: widget.label,
        controller: _text,
        errorText: _error == null ? null : localCopy.resolve(_error!),
        enabled: !_validating,
        autofocus: true,
        maxLines: widget.obscureText ? 1 : null,
        obscureText: widget.obscureText,
        dictation: !widget.obscureText,
        onChanged: (_) {
          if (_error != null) {
            setState(() => _error = null);
          }
        },
      ),
    );
  }
}
