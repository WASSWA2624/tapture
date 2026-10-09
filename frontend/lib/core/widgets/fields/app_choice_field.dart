import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

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
    this.alwaysSheet = false,
    this.wrapLabel = false,
    this.compact = false,
    this.leadingBuilder,
  });

  /// Visible name of the control (FE-A11Y-02).
  final String label;

  /// Options to offer. Length decides segmented versus sheet unless compact.
  final List<Choice<T>> options;

  /// The current selection, or null when empty.
  final T? value;

  /// Called with the picked value. Segmented taps do not clear.
  final ValueChanged<T?> onChanged;

  /// When false, the control does not accept input.
  final bool enabled;

  /// When true, the field always shows its current value and opens the
  /// searchable sheet, whatever the option count. Use it for a switch that
  /// must read as a control even with one option.
  final bool alwaysSheet;

  /// Allows a sheet field's label to wrap at large text or narrow widths.
  /// The label occupies its own row inside the trigger.
  /// The selected value and picker behaviour remain unchanged.
  final bool wrapLabel;

  /// Uses a naturally wrapping dense list-tile trigger for the same sheet.
  final bool compact;

  /// Builds decorative artwork beside each option's readable label.
  /// The selected tick remains visible when a builder is supplied.
  final Widget Function(BuildContext, Choice<T>)? leadingBuilder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      value: _selected?.label,
      child: !compact && !alwaysSheet && options.length < _sheetThreshold
          ? _SegmentedChoice<T>(
              label: label,
              options: options,
              value: value,
              enabled: enabled,
              onChanged: onChanged,
              leadingBuilder: leadingBuilder,
            )
          : _SheetChoice<T>(
              label: label,
              wrapLabel: wrapLabel,
              compact: compact,
              options: options,
              value: value,
              enabled: enabled,
              onChanged: onChanged,
              leadingBuilder: leadingBuilder,
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
    required this.leadingBuilder,
  });

  final String label;
  final List<Choice<T>> options;
  final T? value;
  final bool enabled;
  final ValueChanged<T?> onChanged;
  final Widget Function(BuildContext, Choice<T>)? leadingBuilder;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final BorderSide side = _outline(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _choiceLabel(label, colors),
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
                        leadingBuilder: leadingBuilder,
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
    required this.leadingBuilder,
  });

  final Choice<T> option;
  final bool selected;
  final bool enabled;
  final ValueChanged<T?> onChanged;
  final Widget Function(BuildContext, Choice<T>)? leadingBuilder;

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
                vertical: Space.x1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (leadingBuilder != null) ...<Widget>[
                    ExcludeSemantics(child: leadingBuilder!(context, option)),
                    const SizedBox(width: Space.x1),
                  ],
                  if (selected) ...<Widget>[
                    Icon(AppIcons.check, color: foreground, size: Space.x4),
                    const SizedBox(width: Space.x1),
                  ] else if (leadingBuilder == null &&
                      option.icon != null) ...<Widget>[
                    Icon(option.icon, color: foreground, size: Space.x4),
                    const SizedBox(width: Space.x1),
                  ],
                  Flexible(
                    // Labels wrap rather than clip at large text; the row's
                    // intrinsic height grows every segment together.
                    child: Text(
                      option.label,
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
    required this.wrapLabel,
    required this.compact,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.leadingBuilder,
  });

  final String label;
  final bool wrapLabel;
  final bool compact;
  final List<Choice<T>> options;
  final T? value;
  final bool enabled;
  final ValueChanged<T?> onChanged;
  final Widget Function(BuildContext, Choice<T>)? leadingBuilder;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String selectedLabel = _labelFor(value);
    final Choice<T>? selected = options
        .where((Choice<T> option) => option.value == value)
        .firstOrNull;
    if (compact) {
      return Semantics(
        button: true,
        enabled: enabled,
        child: AppListTile(
          dense: true,
          wrapText: true,
          title: selectedLabel.isEmpty ? label : selectedLabel,
          subtitle: selectedLabel.isEmpty ? null : label,
          leading: leadingBuilder == null || selected == null
              ? null
              : ExcludeSemantics(child: leadingBuilder!(context, selected)),
          trailing: ExcludeSemantics(
            child: Icon(
              AppIcons.expand,
              color: colors.onSurface,
              size: Space.x6,
            ),
          ),
          onTap: enabled ? () => unawaited(_open(context)) : null,
        ),
      );
    }
    final Widget field = InputDecorator(
      isEmpty: selectedLabel.isEmpty,
      decoration: InputDecoration(
        labelText: wrapLabel ? null : label,
        enabled: enabled,
        suffixIcon: ExcludeSemantics(
          child: Icon(AppIcons.expand, color: colors.onSurface, size: Space.x6),
        ),
      ),
      child: leadingBuilder == null || selected == null
          ? Text(
              selectedLabel.isEmpty ? ' ' : selectedLabel,
              style: AppText.body.copyWith(color: colors.onSurface),
            )
          : Row(
              children: <Widget>[
                ExcludeSemantics(child: leadingBuilder!(context, selected)),
                const SizedBox(width: Space.x2),
                Expanded(
                  child: Text(
                    selectedLabel,
                    style: AppText.body.copyWith(color: colors.onSurface),
                  ),
                ),
              ],
            ),
    );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? () => unawaited(_open(context)) : null,
        // The whole trigger is the 48dp target, so the value line is one
        // text line tall and the field matches a labelled text field
        // (FBK0000004).
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
          child: wrapLabel
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _choiceLabel(label, colors),
                    const SizedBox(height: Space.x2),
                    field,
                  ],
                )
              : field,
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
          leadingBuilder: leadingBuilder,
          onPick: (T picked) {
            Navigator.of(sheetContext).pop();
            onChanged(picked);
          },
        );
      },
    );
  }
}

Widget _choiceLabel(String label, AppColors colors) => ExcludeSemantics(
  child: Text(label, style: AppText.label.copyWith(color: colors.onSurface)),
);

class _ChoiceSheet<T> extends StatefulWidget {
  const _ChoiceSheet({
    required this.label,
    required this.options,
    required this.value,
    required this.onPick,
    required this.leadingBuilder,
  });

  final String label;
  final List<Choice<T>> options;
  final T? value;
  final ValueChanged<T> onPick;
  final Widget Function(BuildContext, Choice<T>)? leadingBuilder;

  @override
  State<_ChoiceSheet<T>> createState() => _ChoiceSheetState<T>();
}

class _ChoiceSheetState<T> extends State<_ChoiceSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    final List<Choice<T>> visible = <Choice<T>>[
      for (final Choice<T> option in widget.options)
        if (_labelContains(option.label, _query)) option,
    ];
    // The search control must scroll with the choices when landscape, large
    // text or the keyboard leaves less than one control's height for the body.
    return CustomScrollView(
      semanticChildCount: visible.length,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x3,
              vertical: Space.x2,
            ),
            child: AppSearchField(
              hint: localCopy.search,
              debounce: Duration.zero,
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: AppEmptyState(
              icon: AppIcons.searchEmpty,
              headline: localCopy.choiceNoMatch(_query),
              message: localCopy.searchNoMatchMessage,
            ),
          )
        else
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (BuildContext context, int index) {
              final Choice<T> option = visible[index];
              return AppListTile(
                title: option.label,
                selected: option.value == widget.value,
                wrapText: widget.leadingBuilder != null,
                leading: widget.leadingBuilder != null
                    ? ExcludeSemantics(
                        child: widget.leadingBuilder!(context, option),
                      )
                    : option.icon == null
                    ? null
                    : Icon(option.icon, color: colors.onSurface),
                onTap: () => widget.onPick(option.value),
              );
            },
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
