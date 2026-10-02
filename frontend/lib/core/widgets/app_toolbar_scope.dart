import 'package:flutter/material.dart';

/// Resolved toolbar ink for both ordinary icons and Material 3 controls.
/// Material 3 icon buttons resolve their own theme ahead of IconTheme.
class AppToolbarScope extends StatelessWidget {
  /// Creates a toolbar scope without changing the shared control geometry.
  const AppToolbarScope({required this.ink, required this.child, super.key});

  /// Foreground token for the toolbar's actual background.
  final Color ink;

  /// Toolbar content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style =
        IconButtonTheme.of(context).style ?? const ButtonStyle();
    return IconTheme(
      data: IconTheme.of(context).copyWith(color: ink),
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: style.copyWith(
            foregroundColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.disabled)
                  ? style.foregroundColor?.resolve(states)
                  : ink,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
