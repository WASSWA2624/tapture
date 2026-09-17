import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';

/// The catalogue button. Features compose this instead of a Material button.
class AppButton extends StatelessWidget {
  /// Creates a labelled button. [busy] shows an inline spinner and ignores
  /// presses so a double submission cannot land.
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.busy = false,
    this.icon,
  });

  /// Visible label; also the semantic name of the control (FE-A11Y-02).
  final String label;

  /// Invoked on a press. Null is the disabled state. Ignored while [busy].
  final VoidCallback? onPressed;

  /// Visual role. Destructive still carries the label, never colour alone
  /// (FE-THEME-05).
  final AppButtonVariant variant;

  /// When true, an inline spinner is shown and taps are swallowed.
  final bool busy;

  /// Optional leading icon, hidden while [busy] so the spinner owns that slot.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null && !busy;
    final VoidCallback? visualPress = isDisabled
        ? null
        : () {
            if (!busy) {
              onPressed?.call();
            }
          };
    final AppColors colors = context.colors;
    final Widget child = Builder(
      builder: (BuildContext buttonContext) => _child(buttonContext),
    );
    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: visualPress,
        style: _fillStyle(colors),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: visualPress,
        style: _outlineStyle(colors),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: visualPress,
        style: _textStyle(colors),
        child: child,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: visualPress,
        style: _fillStyle(
          colors,
          background: colors.danger,
          foreground: _onFill(colors.danger, colors),
        ),
        child: child,
      ),
    };
    return Semantics(
      liveRegion: busy,
      child: AbsorbPointer(
        absorbing: busy,
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          heightFactor: 1,
          child: button,
        ),
      ),
    );
  }

  Widget _child(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Space.x2,
      runSpacing: Space.x1,
      children: <Widget>[
        if (busy)
          ExcludeSemantics(
            child: SizedBox(
              width: Space.x5,
              height: Space.x5,
              child: CircularProgressIndicator(
                strokeWidth: Space.x0,
                color: IconTheme.of(context).color,
                value: MediaQuery.disableAnimationsOf(context)
                    ? Space.x3 / Space.x4
                    : null,
              ),
            ),
          )
        else if (icon != null)
          Icon(icon, size: Space.x6),
        Text(
          label,
          style: AppText.label,
          textAlign: TextAlign.center,
          semanticsLabel: busy ? Copy.busyAction(label) : null,
        ),
      ],
    );
  }
}

ButtonStyle _fillStyle(
  AppColors colors, {
  Color? background,
  Color? foreground,
}) {
  return FilledButton.styleFrom(
    backgroundColor: background,
    foregroundColor: foreground,
    disabledBackgroundColor: colors.surfaceVariant,
    disabledForegroundColor: colors.onSurface,
  );
}

ButtonStyle _outlineStyle(AppColors colors) {
  return OutlinedButton.styleFrom(
    disabledForegroundColor: colors.onSurface,
    disabledBackgroundColor: colors.surface,
  );
}

ButtonStyle _textStyle(AppColors colors) {
  return TextButton.styleFrom(disabledForegroundColor: colors.onSurface);
}

/// The four roles [AppButton] can render from tokens.
enum AppButtonVariant {
  /// Filled, the default action on a row of controls.
  primary,

  /// Outlined, visibly secondary to [primary].
  secondary,

  /// Text-only, for the least prominent action.
  text,

  /// Filled with the danger colour; the label still names the action.
  destructive,
}

/// Ink that still reads on [fill] in every mode, using the two surface inks
/// already on [AppColors] rather than a one-off (FE-THEME-11).
Color _onFill(Color fill, AppColors colors) {
  final Color first = colors.surface;
  final Color second = colors.onSurface;
  return _contrastRatio(fill, first) >= _contrastRatio(fill, second)
      ? first
      : second;
}

/// WCAG contrast ratio of [first] against [second]. The 0.05 offset is the
/// constant in that formula, not a spacing token.
double _contrastRatio(Color first, Color second) {
  final double a = first.computeLuminance();
  final double b = second.computeLuminance();
  final double lighter = a > b ? a : b;
  final double darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}
