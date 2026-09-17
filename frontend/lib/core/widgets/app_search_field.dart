import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';

import 'fields/app_text_field.dart';

/// Debounced search input. [onChanged] fires once per debounce window, not
/// once per keystroke. Records, datasets and template pickers reuse this
/// control.
class AppSearchField extends StatefulWidget {
  /// Creates a search field. [debounce] defaults to
  /// [AppConstants.interaction.debounce].
  AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    Duration? debounce,
    this.resultCount,
    this.enabled = true,
  }) : debounce = debounce ?? AppConstants.interaction.debounce;

  /// Empty-state prompt; also the semantic name of the control (FE-A11Y-02).
  final String hint;

  /// Called once after [debounce] of quiet typing, with the current text.
  final ValueChanged<String> onChanged;

  /// Called when the IME submits. Pending debounce is flushed first.
  final VoidCallback? onSubmitted;

  /// Quiet period before [onChanged] fires.
  final Duration debounce;

  /// Optional hit count shown beside the field, formatted for the locale.
  final int? resultCount;

  /// When false, the field does not accept input.
  final bool enabled;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  String _sent = '';

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int? count = widget.resultCount;
    return AppTextField(
      label: widget.hint,
      controller: _controller,
      hint: widget.hint,
      enabled: widget.enabled,
      clearable: true,
      textInputAction: TextInputAction.search,
      keyboardType: TextInputType.text,
      prefix: ExcludeSemantics(
        child: Icon(
          Icons.search,
          color: context.colors.onSurface,
          size: Space.x6,
        ),
      ),
      trailing: count == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.x3),
              child: Text(
                NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toString(),
                ).format(count),
                style: AppText.caption.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
      onChanged: _schedule,
      onSubmitted: (_) => _submit(),
    );
  }

  void _schedule(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => _emit(value));
  }

  void _submit() {
    _timer?.cancel();
    _emit(_controller.text);
    widget.onSubmitted?.call();
  }

  void _emit(String value) {
    if (value == _sent) {
      return;
    }
    _sent = value;
    widget.onChanged(value);
  }
}
