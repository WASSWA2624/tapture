import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

/// Ink swatches and a three-step size for drawing and typing on a photo
/// (FBK0000151, FBK0000152).
///
/// Each swatch is a 48dp target named for its ink, and the chosen one
/// carries a tick and a heavier ring, so the choice is never colour alone
/// (FE-A11Y-01, FE-A11Y-05).
class AppInkPicker extends StatelessWidget {
  /// Creates a picker showing [ink] and [size].
  const AppInkPicker({
    super.key,
    required this.ink,
    required this.size,
    required this.onInk,
    required this.onSize,
  });

  /// The chosen ink.
  final MarkupInk ink;

  /// The chosen size: 0 small, 1 medium, 2 large, an index into
  /// [AppConstants.markup].
  final int size;

  /// Called with a tapped ink.
  final ValueChanged<MarkupInk> onInk;

  /// Called with a picked size index.
  final ValueChanged<int> onSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(Copy.markupInkLabel, style: AppText.caption),
        const SizedBox(height: Space.x1),
        Semantics(
          container: true,
          label: Copy.markupInkLabel,
          child: Wrap(
            spacing: Space.x1,
            runSpacing: Space.x1,
            children: <Widget>[
              for (final MarkupInk option in MarkupInk.values)
                _Swatch(
                  ink: option,
                  selected: option == ink,
                  onTap: () => onInk(option),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.x2),
        AppChoiceField<int>(
          label: Copy.markupSize,
          value: size.clamp(0, _sizes.length - 1),
          options: _sizes,
          onChanged: (int? next) {
            if (next != null) {
              onSize(next);
            }
          },
        ),
      ],
    );
  }
}

/// Relative luminance above which a black tick reads better than a white
/// one on an ink swatch.
const double _lightInk = 0.4;

const List<Choice<int>> _sizes = <Choice<int>>[
  Choice<int>(0, Copy.markupSizeSmall),
  Choice<int>(1, Copy.markupSizeMedium),
  Choice<int>(2, Copy.markupSizeLarge),
];

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.ink,
    required this.selected,
    required this.onTap,
  });

  final MarkupInk ink;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String name = Copy.markupInk(ink);
    final Color tick = ink.color.computeLuminance() > _lightInk
        ? MarkupInk.black.color
        : MarkupInk.white.color;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: name,
        child: SizedBox.square(
          key: ValueKey<String>('ink-${ink.name}'),
          dimension: Sizes.minTapTarget,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ink.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? colors.onSurface : colors.outline,
                      width: selected ? Space.x0 * 1.5 : Space.x0 / 2,
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: Space.x8,
                    child: selected
                        ? Icon(AppIcons.check, size: Space.x5, color: tick)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
