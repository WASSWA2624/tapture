import 'package:flutter/material.dart';
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
  });

  /// The icon to draw. Colour and the default size come from the theme.
  final IconData icon;

  /// Name announced to assistive technology.
  final String semanticLabel;

  /// Name shown on long-press and to pointer users.
  final String tooltip;

  /// Invoked on a press. Null is the disabled state.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints.tightFor(
        width: Sizes.minTapTarget,
        height: Sizes.minTapTarget,
      ),
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.zero),
        minimumSize: WidgetStatePropertyAll<Size>(
          Size(Sizes.minTapTarget, Sizes.minTapTarget),
        ),
        maximumSize: WidgetStatePropertyAll<Size>(
          Size(Sizes.minTapTarget, Sizes.minTapTarget),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        iconSize: WidgetStatePropertyAll<double>(Space.x6),
      ),
      iconSize: Space.x6,
      icon: Icon(icon, size: Space.x6, semanticLabel: semanticLabel),
    );
  }
}
