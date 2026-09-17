import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';

import 'app_text_field.dart';
import 'choice.dart';

/// Multiple selection. The closed field shows the current values as chips;
/// tapping it opens a searchable sheet with select-all and clear.
class AppMultiChoiceField<T> extends StatelessWidget {
  /// Creates a multi-choice field. [value] is never mutated; a new [Set] is
  /// reported on every change.
  const AppMultiChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  /// Visible name of the control (FE-A11Y-02).
  final String label;

  /// Options to offer. Labels are template content (FE-L10N-07).
  final List<Choice<T>> options;

  /// Currently selected values. Order on screen follows [options].
  final Set<T> value;

  /// Called with a new set; the previous [value] is left untouched.
  final ValueChanged<Set<T>> onChanged;

  /// When false, the control does not open the sheet.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final List<Choice<T>> selected = <Choice<T>>[
      for (final Choice<T> option in options)
        if (value.contains(option.value)) option,
    ];
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      value: selected.map((Choice<T> option) => option.label).join(', '),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? () => unawaited(_open(context)) : null,
          child: InputDecorator(
            isEmpty: selected.isEmpty,
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
              child: selected.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.x2),
                      child: ExcludeSemantics(
                        child: AppChipRow(
                          chips: <AppChip>[
                            for (final Choice<T> option in selected)
                              AppChip(label: option.label, selected: true),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    await showAppSheet<void>(
      context,
      title: label,
      builder: (BuildContext sheetContext) {
        return _MultiChoiceSheet<T>(
          label: label,
          options: options,
          value: value,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _MultiChoiceSheet<T> extends StatefulWidget {
  const _MultiChoiceSheet({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Choice<T>> options;
  final Set<T> value;
  final ValueChanged<Set<T>> onChanged;

  @override
  State<_MultiChoiceSheet<T>> createState() => _MultiChoiceSheetState<T>();
}

class _MultiChoiceSheetState<T> extends State<_MultiChoiceSheet<T>> {
  final TextEditingController _search = TextEditingController();
  late Set<T> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.of(widget.value);
  }

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x2),
          child: Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: Copy.selectAll,
                  variant: AppButtonVariant.text,
                  onPressed: visible.isEmpty
                      ? null
                      : () => _emit(<T>{
                          ..._selected,
                          for (final Choice<T> option in visible) option.value,
                        }),
                ),
              ),
              Expanded(
                child: AppButton(
                  label: Copy.clear,
                  variant: AppButtonVariant.text,
                  onPressed: _selected.isEmpty ? null : () => _emit(<T>{}),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: visible.length,
            itemBuilder: (BuildContext context, int index) {
              final Choice<T> option = visible[index];
              final bool selected = _selected.contains(option.value);
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
                onTap: () {
                  final Set<T> next = Set<T>.of(_selected);
                  if (selected) {
                    next.remove(option.value);
                  } else {
                    next.add(option.value);
                  }
                  _emit(next);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _emit(Set<T> next) {
    setState(() => _selected = next);
    widget.onChanged(Set<T>.unmodifiable(next));
  }
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
