import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

import 'app_text_field.dart';

/// Numeric entry with an optional unit suffix and range, built on
/// [AppTextField].
class AppNumberField extends StatefulWidget {
  /// Creates a number field. Non-numeric keystrokes are dropped as they are
  /// typed. Out-of-range values keep the text and use the shared error style.
  const AppNumberField({
    super.key,
    required this.label,
    required this.onChanged,
    this.unit,
    this.min,
    this.max,
    this.decimal = false,
    this.enabled = true,
  });

  /// Visible label; also the semantic name of the control (FE-A11Y-02).
  final String label;

  /// Called with the parsed number, or null while the field is empty or
  /// incomplete.
  final ValueChanged<num?> onChanged;

  /// Template unit shown as a suffix, for example `kg`.
  final String? unit;

  /// Inclusive lower bound. Null means no lower bound.
  final num? min;

  /// Inclusive upper bound. Null means no upper bound.
  final num? max;

  /// When true, a decimal separator is accepted.
  final bool decimal;

  /// When false, the field does not accept input.
  final bool enabled;

  @override
  State<AppNumberField> createState() => _AppNumberFieldState();
}

class _AppNumberFieldState extends State<AppNumberField> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? unit = widget.unit;
    return AppTextField(
      label: widget.label,
      controller: _controller,
      enabled: widget.enabled,
      errorText: _errorText,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.decimal,
        signed: true,
      ),
      inputFormatters: <TextInputFormatter>[
        _NumericFormatter(decimal: widget.decimal),
      ],
      trailing: unit == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.x3),
              child: Text(
                unit,
                style: AppText.label.copyWith(color: context.colors.onSurface),
              ),
            ),
      onChanged: _handleChange,
    );
  }

  void _handleChange(String raw) {
    final num? parsed = _parse(raw);
    final String? error = _rangeError(parsed);
    setState(() => _errorText = error);
    widget.onChanged(parsed);
  }

  String? _rangeError(num? parsed) {
    if (parsed == null) {
      return null;
    }
    final num? min = widget.min;
    final num? max = widget.max;
    final bool tooLow = min != null && parsed < min;
    final bool tooHigh = max != null && parsed > max;
    if (!tooLow && !tooHigh) {
      return null;
    }
    return 'Out of range';
  }

  num? _parse(String raw) {
    if (raw.isEmpty ||
        raw == '-' ||
        raw == '.' ||
        raw == ',' ||
        raw == '-.' ||
        raw == '-,') {
      return null;
    }
    return num.tryParse(raw.replaceAll(',', '.'));
  }
}

/// Drops characters that would make [num.tryParse] fail, so a letter cannot
/// land in the field.
class _NumericFormatter extends TextInputFormatter {
  const _NumericFormatter({required this.decimal});

  final bool decimal;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String cleaned = newValue.text.replaceAll(RegExp('[^0-9.,\\-]'), '');
    if (_isAllowed(cleaned)) {
      if (cleaned == newValue.text) {
        return newValue;
      }
      return TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
    return oldValue;
  }

  bool _isAllowed(String text) {
    if (text.isEmpty || text == '-') {
      return true;
    }
    if (decimal &&
        (text == '.' || text == ',' || text == '-.' || text == '-,')) {
      return true;
    }
    if (!decimal && text.contains(RegExp('[.,]'))) {
      return false;
    }
    return num.tryParse(text.replaceAll(',', '.')) != null;
  }
}
