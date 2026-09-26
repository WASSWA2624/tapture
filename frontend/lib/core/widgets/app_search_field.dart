import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';

import 'fields/app_text_field.dart';

/// Debounced search input. [onChanged] fires once per debounce window, not
/// once per keystroke. Records, datasets and template pickers reuse this
/// control. A list with something to filter by passes [onFilter], and every
/// such list shows the same filter button (FBK0000003).
class AppSearchField extends StatefulWidget {
  /// Creates a search field. [debounce] defaults to
  /// [AppConstants.interaction.debounce].
  AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.text,
    this.onSubmitted,
    Duration? debounce,
    this.resultCount,
    this.afterMic,
    this.onFilter,
    this.activeFilterCount = 0,
    this.enabled = true,
  }) : debounce = debounce ?? AppConstants.interaction.debounce;

  /// Empty-state prompt; also the semantic name of the control (FE-A11Y-02).
  final String hint;

  /// Called once after [debounce] of quiet typing, with the current text.
  final ValueChanged<String> onChanged;

  /// The parent's applied query. When this becomes empty the field clears,
  /// so Clear filters cannot leave stale text. Omitted, the field is only
  /// cleared from inside. Typing is not overwritten while this is still
  /// empty or still matches the last emit.
  final String? text;

  /// Called when the IME submits. Pending debounce is flushed first.
  final VoidCallback? onSubmitted;

  /// Quiet period before [onChanged] fires.
  final Duration debounce;

  /// Optional hit count shown beside the field, formatted for the locale.
  final int? resultCount;

  /// Control drawn immediately after the microphone, for anything that is
  /// not a filter. Null hides it.
  final Widget? afterMic;

  /// Opens the list's filters from a filter button drawn after the
  /// microphone. Null draws no filter button.
  final VoidCallback? onFilter;

  /// How many filters are on. Above zero the filter button reads as
  /// selected and names the count (FE-A11Y-05).
  final int activeFilterCount;

  /// When false, the field does not accept input.
  final bool enabled;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );
  Timer? _timer;
  late String _sent = widget.text ?? '';

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? text = widget.text;
    final String? previous = oldWidget.text;
    if (text != null &&
        text.isEmpty &&
        previous != null &&
        previous.isNotEmpty) {
      _timer?.cancel();
      if (_controller.text.isNotEmpty) {
        _controller.clear();
      }
      _sent = '';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int? count = widget.resultCount;
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);
    final BorderSide side = switch (theme.inputDecorationTheme.enabledBorder) {
      final OutlineInputBorder border => border.borderSide,
      _ => BorderSide(
        color: colors.outline,
        width: Space.x0 / 2,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
    };
    final OutlineInputBorder box = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.sm),
      borderSide: side,
    );
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: colors.surfaceVariant,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: box,
          enabledBorder: box,
          focusedBorder: box,
          errorBorder: box.copyWith(
            borderSide: side.copyWith(color: colors.danger),
          ),
          focusedErrorBorder: box.copyWith(
            borderSide: side.copyWith(color: colors.danger),
          ),
        ),
      ),
      child: AppTextField(
        label: widget.hint,
        controller: _controller,
        hint: widget.hint,
        enabled: widget.enabled,
        clearable: true,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        prefix: ExcludeSemantics(
          child: Icon(AppIcons.search, color: colors.onSurface, size: Space.x6),
        ),
        afterDictation: _afterMic(),
        trailing: count == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: Space.x3),
                child: Text(
                  NumberFormat.decimalPattern(
                    Localizations.localeOf(context).toString(),
                  ).format(count),
                  style: AppText.caption.copyWith(color: colors.onSurface),
                ),
              ),
        onChanged: _schedule,
        onSubmitted: (_) => _submit(),
      ),
    );
  }

  Widget? _afterMic() {
    final Widget? extra = widget.afterMic;
    final VoidCallback? onFilter = widget.onFilter;
    if (onFilter == null) {
      return extra;
    }
    final int active = widget.activeFilterCount;
    final String label = Copy.searchFilters(active);
    final Widget filter = AppIconButton(
      key: const ValueKey<String>('search-filter'),
      icon: AppIcons.filter,
      tooltip: label,
      semanticLabel: label,
      selected: active > 0 ? true : null,
      outlined: false,
      onPressed: onFilter,
    );
    if (extra == null) {
      return filter;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[extra, filter],
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
