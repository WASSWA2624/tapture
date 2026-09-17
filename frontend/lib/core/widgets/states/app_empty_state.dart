import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// Helpful empty view: icon, headline, one-line explanation, optional
/// next action (FE-SIMP-11). Screens do not leave blank space.
class AppEmptyState extends StatelessWidget {
  /// Creates an empty state. [onAction] is offered only with [actionLabel].
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Leading glyph. Colour is never the only signal (FE-A11Y-05).
  final IconData icon;

  /// Short title; also the semantic name of the panel (FE-A11Y-02).
  final String headline;

  /// One-line explanation of why the view is empty.
  final String message;

  /// Label of the optional primary action. Null hides the button.
  final String? actionLabel;

  /// Invoked by the optional primary action. Null hides the button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String? actionLabel = this.actionLabel;
    final VoidCallback? onAction = this.onAction;
    return Semantics(
      container: true,
      label: headline,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x3,
          vertical: Space.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: Space.x10, color: colors.secondary),
            const SizedBox(height: Space.x3),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: AppText.section.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: Space.x2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: colors.onSurface),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: Space.x4),
              AppButton(label: actionLabel, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
