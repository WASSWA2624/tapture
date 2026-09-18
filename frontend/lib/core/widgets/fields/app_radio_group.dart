import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

import 'choice.dart';
import 'choice_layout.dart';

/// Single selection as a labelled radio list. Use this when every option
/// should stay on screen; [AppChoiceField] is the segmented control or
/// searchable sheet.
///
/// [Axis.horizontal] puts short options side by side without a frame. When
/// they do not fit on one line they fall into even columns rather than a
/// ragged wrap, so four options become two rows of two on a narrow phone.
class AppRadioGroup<T> extends StatelessWidget {
  /// Creates a radio group. [options] are shown as given (FE-L10N-07).
  const AppRadioGroup({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.enabled = true,
    this.direction = Axis.vertical,
    this.showLabel = true,
  });

  /// Visible name of the group (FE-A11Y-02).
  final String label;

  /// Options to offer, in visual and traversal order (FE-A11Y-06).
  final List<Choice<T>> options;

  /// The current selection, or null when empty.
  final T? value;

  /// Called with the picked value. A tap does not clear.
  final ValueChanged<T> onChanged;

  /// When false, the group does not accept input.
  final bool enabled;

  /// Vertical lists options in an outlined frame; horizontal lays short
  /// options side by side.
  final Axis direction;

  /// When false, [label] is still the group's semantic name but is not
  /// drawn, for a screen whose title already says what is being chosen.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return _horizontal(context);
    }
    final AppColors colors = context.colors;
    final BorderSide side = _outline(context);
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExcludeSemantics(
            child: Text(
              label,
              style: AppText.label.copyWith(color: colors.onSurface),
            ),
          ),
          const SizedBox(height: Space.x2),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
              side: side,
            ),
            clipBehavior: Clip.antiAlias,
            child: RadioGroup<T>(
              groupValue: value,
              onChanged: _handleChanged,
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < options.length; i++) ...<Widget>[
                    if (i > 0)
                      Divider(
                        height: side.width,
                        thickness: side.width,
                        color: colors.outline,
                      ),
                    _RadioOption<T>(
                      option: options[i],
                      selected: options[i].value == value,
                      enabled: enabled,
                      onChanged: onChanged,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horizontal(BuildContext context) {
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
          RadioGroup<T>(
            groupValue: value,
            onChanged: _handleChanged,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double? cell = evenChoiceWidth(context, <String>[
                  for (final Choice<T> option in options) option.label,
                ], constraints.maxWidth);
                return Wrap(
                  spacing: choiceGap,
                  children: <Widget>[
                    for (final Choice<T> option in options)
                      SizedBox(
                        width: cell,
                        child: _RadioOption<T>(
                          option: option,
                          selected: option.value == value,
                          enabled: enabled,
                          onChanged: onChanged,
                          compact: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleChanged(T? next) {
    if (!enabled || next == null) {
      return;
    }
    onChanged(next);
  }
}

class _RadioOption<T> extends StatelessWidget {
  const _RadioOption({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    this.compact = false,
  });

  final Choice<T> option;
  final bool selected;
  final bool enabled;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return MergeSemantics(
      child: Semantics(
        enabled: enabled,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        label: option.label,
        onTap: enabled ? () => onChanged(option.value) : null,
        child: InkWell(
          onTap: enabled ? () => onChanged(option.value) : null,
          borderRadius: compact
              ? const BorderRadius.all(Radius.circular(Radii.sm))
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
            child: Padding(
              padding: compact
                  ? const EdgeInsetsDirectional.only(end: Space.x2)
                  : const EdgeInsets.symmetric(
                      horizontal: Space.x3,
                      vertical: Space.x1,
                    ),
              child: Row(
                mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                children: <Widget>[
                  IgnorePointer(
                    child: ExcludeSemantics(
                      child: Radio<T>(
                        value: option.value,
                        enabled: enabled,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: compact
                            ? compactChoiceDensity
                            : VisualDensity.compact,
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? Space.x1 : Space.x2),
                  Flexible(
                    fit: compact ? FlexFit.loose : FlexFit.tight,
                    child: Text(
                      option.label,
                      style: (compact ? AppText.label : AppText.body).copyWith(
                        color: colors.onSurface,
                      ),
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

BorderSide _outline(BuildContext context) {
  final double width = Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2;
  return BorderSide(color: context.colors.outline, width: width);
}
