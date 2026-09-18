import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';

/// An icon-only action that cannot be constructed without a name.
///
/// [semanticLabel] and [tooltip] are required so an unlabelled icon button
/// does not compile (FE-A11Y-02).
class AppIconButton extends StatelessWidget {
  /// Creates an icon-only control. Both [semanticLabel] and [tooltip] must be
  /// supplied; they may be the same string.
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.tooltip,
    this.onPressed,
    this.selected,
    this.outlined = true,
  });

  /// The icon to draw. Colour and the default size come from the theme.
  final IconData icon;

  /// Name announced to assistive technology.
  final String semanticLabel;

  /// Name shown on long-press and to pointer users.
  final String tooltip;

  /// Invoked on a press. Null is the disabled state.
  final VoidCallback? onPressed;

  /// Null for a plain action. Otherwise the control is a toggle, filled
  /// while on and announced as selected, so state is never colour alone
  /// (FE-A11Y-05). Pair it with a [tooltip] that names the next press.
  final bool? selected;

  /// When false, the control has no outline, for one that sits inside a
  /// field or over an image. The widget style wins over the theme's.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool on = selected ?? false;
    final BorderSide outline = outlined
        ? BorderSide(
            color: on ? colors.primary : colors.outline,
            width: Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2,
            strokeAlign: BorderSide.strokeAlignInside,
          )
        : BorderSide.none;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      isSelected: selected,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints.tightFor(
        width: Sizes.minTapTarget,
        height: Sizes.minTapTarget,
      ),
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(Space.x0),
        minimumSize: const Size(Sizes.minTapTarget, Sizes.minTapTarget),
        maximumSize: const Size(Sizes.minTapTarget, Sizes.minTapTarget),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        iconSize: Space.x6,
        backgroundColor: on ? colors.primary : null,
        foregroundColor: on ? colors.onPrimary : null,
        side: outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.sm)),
        ),
      ),
      iconSize: Space.x6,
      icon: Icon(icon, size: Space.x6, semanticLabel: semanticLabel),
    );
  }
}
