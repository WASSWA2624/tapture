import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// Helpful empty view: icon, headline, one-line explanation, optional
/// next action (FE-SIMP-11). Screens do not leave blank space.
///
/// The next action is either a button under the message, or the icon itself
/// when [onIconTap] and [iconLabel] are set, never both.
class AppEmptyState extends StatelessWidget {
  /// Creates an empty state. [onAction] is offered only with [actionLabel];
  /// [onIconTap] makes the icon the action only with [iconLabel].
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onIconTap,
    this.iconLabel,
  }) : assert(
         onIconTap == null || actionLabel == null,
         'the next action is the icon or a button, not both',
       );

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

  /// Makes the icon the next action, a labelled button with focus and hover
  /// feedback and at least a 48dp target (FE-A11Y-01). Null leaves a plain
  /// icon, as does a null [iconLabel].
  final VoidCallback? onIconTap;

  /// Name and tooltip of the icon when it is the action (FE-A11Y-02).
  final String? iconLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String? actionLabel = this.actionLabel;
    final VoidCallback? onAction = this.onAction;
    final VoidCallback? onIconTap = this.onIconTap;
    final String? iconLabel = this.iconLabel;
    return Semantics(
      container: true,
      label: headline,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (onIconTap != null && iconLabel != null)
              _WellButton(
                icon: icon,
                label: iconLabel,
                color: colors.secondary,
                fill: colors.surfaceVariant,
                onTap: onIconTap,
              )
            else
              _Well(
                icon: icon,
                color: colors.secondary,
                fill: colors.surfaceVariant,
              ),
            const SizedBox(height: Space.x4),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: AppText.section.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: Space.x2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: colors.onSurface),
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

class _Well extends StatelessWidget {
  const _Well({required this.icon, required this.color, required this.fill});

  final IconData icon;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Space.x12 + Space.x8,
      height: Space.x12 + Space.x8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: Space.x0 / 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Icon(icon, size: Space.x10, color: color),
      ),
    );
  }
}

/// The well as the empty state's action: the same circle on a [Material]
/// so ink, focus and hover show on it, named for screen readers and
/// tooltips.
class _WellButton extends StatelessWidget {
  const _WellButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.fill,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const CircleBorder circle = CircleBorder();
    // Its own node, so the panel's name stays the headline and the action
    // is reached as a separate button.
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Material(
          color: fill,
          clipBehavior: Clip.antiAlias,
          shape: CircleBorder(
            side: BorderSide(
              color: color,
              width: Space.x0 / 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: InkWell(
            key: const ValueKey<String>('empty-state-icon-action'),
            customBorder: circle,
            onTap: onTap,
            child: SizedBox(
              width: Space.x12 + Space.x8,
              height: Space.x12 + Space.x8,
              child: Icon(icon, size: Space.x10, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
