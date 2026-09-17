import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';

import 'app_text_field.dart';

/// Date, time or date-time entry. The displayed value is formatted with
/// [DateFormat] against the active locale (FE-L10N-04). Time comes from a
/// [Clock], never [DateTime.now] (FE-STR-11).
class AppDateField extends StatefulWidget {
  /// Creates a temporal field. [clock] defaults to [SystemClock]; tests pass
  /// a [FixedClock].
  const AppDateField({
    super.key,
    required this.label,
    required this.onChanged,
    this.mode = DateFieldMode.date,
    this.value,
    this.autoFilled = false,
    this.enabled = true,
    this.clock = const SystemClock(),
  });

  /// Visible label; also the semantic name of the control (FE-A11Y-02).
  final String label;

  /// Called with the picked instant, or null when the field is cleared.
  final ValueChanged<DateTime?> onChanged;

  /// Which parts of a timestamp this field edits.
  final DateFieldMode mode;

  /// The current value. Null is empty.
  final DateTime? value;

  /// When true, the value was filled in rather than picked, and the auto
  /// affordance is shown (icon and copy, not colour alone — FE-THEME-05).
  final bool autoFilled;

  /// When false, the field does not open the picker.
  final bool enabled;

  /// Source of "now" for the picker and for an empty default.
  final Clock clock;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncText();
  }

  @override
  void didUpdateWidget(AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.mode != widget.mode) {
      _syncText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? value = widget.value;
    final bool showAuto = widget.autoFilled && value != null;
    return AppTextField(
      label: widget.label,
      controller: _controller,
      enabled: widget.enabled,
      readOnly: true,
      helper: showAuto ? Copy.autoFilled : null,
      prefix: showAuto
          ? Icon(
              Icons.auto_awesome,
              semanticLabel: Copy.autoFilled,
              color: context.colors.secondary,
              size: Space.x6,
            )
          : null,
      trailing: value == null || !widget.enabled
          ? null
          : AppIconButton(
              icon: Icons.clear,
              semanticLabel: Copy.clearField(widget.label),
              tooltip: Copy.clearField(widget.label),
              onPressed: () => widget.onChanged(null),
            ),
      onTap: widget.enabled ? () => unawaited(_open()) : null,
    );
  }

  void _syncText() {
    final DateTime? value = widget.value;
    final String next = value == null ? '' : _format(value);
    if (_controller.text != next) {
      _controller.value = TextEditingValue(text: next);
    }
  }

  Future<void> _open() async {
    final DateTime now = _wall(widget.clock.nowUtc().add(widget.clock.offset));
    final DateTime initial = widget.value == null ? now : _wall(widget.value!);
    DateTime picked = initial;
    if (widget.mode == DateFieldMode.date ||
        widget.mode == DateFieldMode.dateTime) {
      final DateTime? date = await showDatePicker(
        context: context,
        initialDate: DateTime(initial.year, initial.month, initial.day),
        firstDate: DateTime(initial.year - _yearWindow),
        lastDate: DateTime(initial.year + _yearWindow),
      );
      if (date == null) {
        return;
      }
      picked = DateTime(
        date.year,
        date.month,
        date.day,
        initial.hour,
        initial.minute,
      );
    }
    if (widget.mode == DateFieldMode.time ||
        widget.mode == DateFieldMode.dateTime) {
      if (!mounted) {
        return;
      }
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: picked.hour, minute: picked.minute),
      );
      if (time == null) {
        return;
      }
      picked = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    }
    widget.onChanged(picked);
  }

  String _format(DateTime value) {
    final String locale = Localizations.localeOf(context).toString();
    final DateTime wall = _wall(value);
    return switch (widget.mode) {
      DateFieldMode.date => DateFormat.yMMMd(locale).format(wall),
      DateFieldMode.time => DateFormat.jm(locale).format(wall),
      DateFieldMode.dateTime => DateFormat.yMMMd(locale).add_jm().format(wall),
    };
  }
}

/// Which parts of a timestamp [AppDateField] edits.
enum DateFieldMode {
  /// Calendar date only.
  date,

  /// Time of day only.
  time,

  /// Calendar date and time of day.
  dateTime,
}

/// How far the picker can move from the initial year.
const int _yearWindow = 100;

/// Wall-clock components, so [DateFormat] does not shift a UTC value into
/// the device zone.
DateTime _wall(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
  );
}
