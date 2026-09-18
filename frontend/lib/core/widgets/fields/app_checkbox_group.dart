import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

import 'choice.dart';
import 'choice_layout.dart';

/// Multiple selection as a labelled checkbox wrap. Use this when every
/// option should stay on screen; [AppMultiChoiceField] is the sheet.
///
/// Options wrap into even columns when they do not fit on one line, so a
/// filter's types stay aligned on a narrow phone.
class AppCheckboxGroup<T> extends StatelessWidget {
  /// Creates a checkbox group. [options] are shown as given (FE-L10N-07).
  const AppCheckboxGroup({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.showLabel = true,
  });

  /// Visible name of the group (FE-A11Y-02).
  final String label;

  /// Options to offer, in visual and traversal order (FE-A11Y-06).
  final List<Choice<T>> options;

  /// The current selection. Empty means none, which a filter treats as all.
  final Set<T> value;

  /// Called with a replacement set; [value] is not mutated.
  final ValueChanged<Set<T>> onChanged;

  /// When false, the group does not accept input.
  final bool enabled;

  /// When false, [label] is still the group's semantic name but is not
  /// drawn, for a screen whose title already says what is being chosen.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showLabel) ...<Widget>[
            ExcludeSemantics(
              child: Text(
                label,
                style: AppText.label.copyWith(color: context.colors.onSurface),
              ),
            ),
            const SizedBox(height: Space.x1),
          ],
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double? cell = evenChoiceWidth(context, <String>[
                for (final Choice<T> option in options) option.label,
              ], constraints.maxWidth);
              return Wrap(
                spacing: choiceGap,
                runSpacing: Space.x0,
                children: <Widget>[
                  for (final Choice<T> option in options)
                    SizedBox(
                      width: cell,
                      child: _CheckboxOption<T>(
                        option: option,
                        selected: value.contains(option.value),
                        enabled: enabled,
                        onChanged: _toggle,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggle(T option) {
    if (!enabled) {
      return;
    }
    final Set<T> next = Set<T>.of(value);
    if (!next.add(option)) {
      next.remove(option);
    }
    onChanged(next);
  }
}

class _CheckboxOption<T> extends StatelessWidget {
  const _CheckboxOption({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final Choice<T> option;
  final bool selected;
  final bool enabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return MergeSemantics(
      child: Semantics(
        enabled: enabled,
        checked: selected,
        button: true,
        label: option.label,
        onTap: enabled ? () => onChanged(option.value) : null,
        child: InkWell(
          onTap: enabled ? () => onChanged(option.value) : null,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.x2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IgnorePointer(
                    child: ExcludeSemantics(
                      child: Checkbox(
                        value: selected,
                        onChanged: enabled ? (_) {} : null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: compactChoiceDensity,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.x1),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      option.label,
                      style: AppText.label.copyWith(color: colors.onSurface),
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
