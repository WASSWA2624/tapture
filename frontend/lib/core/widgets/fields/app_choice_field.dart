import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';

import 'app_text_field.dart';
import 'choice.dart';

/// Single selection. Fewer than [_sheetThreshold] options render as a
/// segmented control; at that count and above, a searchable sheet opens.
class AppChoiceField<T> extends StatelessWidget {
  /// Creates a choice field. [options] are shown as given (FE-L10N-07).
  const AppChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.enabled = true,
  });

  /// Visible name of the control (FE-A11Y-02).
  final String label;

  /// Options to offer. Length decides segmented versus sheet.
  final List<Choice<T>> options;

  /// The current selection, or null when empty.
  final T? value;

  /// Called with the picked value. Segmented taps do not clear.
  final ValueChanged<T?> onChanged;

  /// When false, the control does not accept input.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      value: _selected?.label,
      child: options.length < _sheetThreshold
          ? _SegmentedChoice<T>(
              label: label,
              options: options,
              value: value,
              enabled: enabled,
              onChanged: onChanged,
            )
          : _SheetChoice<T>(
              label: label,
              options: options,
              value: value,
              enabled: enabled,
              onChanged: onChanged,
            ),
    );
  }

  Choice<T>? get _selected {
    for (final Choice<T> option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }
}

/// Count at which presentation switches from segments to a sheet.
const int _sheetThreshold = 4;

class _SegmentedChoice<T> extends StatelessWidget {
  const _SegmentedChoice({
    required this.label,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final List<Choice<T>> options;
  final T? value;
  final bool enabled;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final BorderSide side = _outline(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            label,
            style: AppText.label.copyWith(color: colors.onSurface),
          ),
        ),
        const SizedBox(height: Space.x2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
            border: Border.fromBorderSide(side),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < options.length; i++) ...<Widget>[
                    if (i > 0)
                      ColoredBox(
                        color: colors.outline,
                        child: SizedBox(width: side.width),
                      ),
                    Expanded(
                      child: _Segment<T>(
                        option: options[i],
                        selected: options[i].value == value,
                        enabled: enabled,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final Choice<T> option;
  final bool selected;
  final bool enabled;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color background = !enabled
        ? (selected ? colors.surfaceVariant : colors.surface)
        : (selected ? colors.primary : colors.surface);
    final Color foreground = selected && enabled
        ? colors.onPrimary
        : colors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: option.label,
      child: Material(
        color: background,
        child: InkWell(
          onTap: enabled ? () => onChanged(option.value) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x2,
                vertical: Space.x2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (selected) ...<Widget>[
                    Icon(Icons.check, color: foreground, size: Space.x4),
                    const SizedBox(width: Space.x1),
                  ] else if (option.icon != null) ...<Widget>[
                    Icon(option.icon, color: foreground, size: Space.x4),
                    const SizedBox(width: Space.x1),
                  ],
                  Flexible(
                    child: Text(
                      option.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetChoice<T> extends StatelessWidget {
  const _SheetChoice({
    required this.label,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final List<Choice<T>> options;
  final T? value;
  final bool enabled;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String selectedLabel = _labelFor(value);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? () => unawaited(_open(context)) : null,
        child: InputDecorator(
          isEmpty: selectedLabel.isEmpty,
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            suffixIcon: ExcludeSemantics(
              child: Icon(
                Icons.expand_more,
                color: colors.onSurface,
                size: Space.x6,
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                selectedLabel.isEmpty ? ' ' : selectedLabel,
                style: AppText.body.copyWith(color: colors.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(T? current) {
    for (final Choice<T> option in options) {
      if (option.value == current) {
        return option.label;
      }
    }
    return '';
  }

  Future<void> _open(BuildContext context) async {
    await showAppSheet<void>(
      context,
      title: label,
      builder: (BuildContext sheetContext) {
        return _ChoiceSheet<T>(
          label: label,
          options: options,
          value: value,
          onPick: (T picked) {
            Navigator.of(sheetContext).pop();
            onChanged(picked);
          },
        );
      },
    );
  }
}

class _ChoiceSheet<T> extends StatefulWidget {
  const _ChoiceSheet({
    required this.label,
    required this.options,
    required this.value,
    required this.onPick,
  });

  final String label;
  final List<Choice<T>> options;
  final T? value;
  final ValueChanged<T> onPick;

  @override
  State<_ChoiceSheet<T>> createState() => _ChoiceSheetState<T>();
}

class _ChoiceSheetState<T> extends State<_ChoiceSheet<T>> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final List<Choice<T>> visible = <Choice<T>>[
      for (final Choice<T> option in widget.options)
        if (_labelContains(option.label, _query)) option,
    ];
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.x4,
            vertical: Space.x2,
          ),
          child: AppTextField(
            label: widget.label,
            controller: _search,
            clearable: true,
            prefix: ExcludeSemantics(
              child: Icon(
                Icons.search,
                color: colors.onSurface,
                size: Space.x6,
              ),
            ),
            onChanged: (String value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: visible.length,
            itemBuilder: (BuildContext context, int index) {
              final Choice<T> option = visible[index];
              final bool selected = option.value == widget.value;
              return ListTile(
                minTileHeight: Sizes.minTapTarget,
                selected: selected,
                leading: option.icon == null
                    ? null
                    : Icon(option.icon, color: colors.onSurface),
                title: Text(
                  option.label,
                  style: AppText.body.copyWith(color: colors.onSurface),
                ),
                trailing: selected
                    ? Icon(Icons.check, color: colors.primary)
                    : null,
                onTap: () => widget.onPick(option.value),
              );
            },
          ),
        ),
      ],
    );
  }
}

BorderSide _outline(BuildContext context) {
  final double width = Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2;
  return BorderSide(color: context.colors.outline, width: width);
}

/// Filter by literal containment. Labels are not translated or normalised
/// against UI copy (FE-L10N-07); only the query is case-folded so typing
/// still finds the option.
bool _labelContains(String label, String query) {
  if (query.isEmpty) {
    return true;
  }
  return label.toLowerCase().contains(query.toLowerCase());
}
