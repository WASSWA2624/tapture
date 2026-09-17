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
      constraints: const BoxConstraints(
        minWidth: Sizes.minTapTarget,
        minHeight: Sizes.minTapTarget,
      ),
      icon: Icon(icon, semanticLabel: semanticLabel),
    );
  }
}
