part of 'app_overflow_menu.dart';

/// One labelled command inside [AppOverflowMenu].
///
/// Visible title-bar actions stay icon-only; these rows always show
/// [label] so a menu command is never colour or icon alone (FE-A11Y-05).
final class AppOverflowAction {
  /// Creates a menu row. [label] is the visible name and the semantic name.
  const AppOverflowAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.key,
  });

  /// Optional leading glyph. Meaning still comes from [label].
  final IconData? icon;

  /// Visible text of the row (FE-A11Y-02).
  final String label;

  /// Invoked when the row is chosen.
  final VoidCallback onTap;

  /// Optional key for tests and the menu row.
  final Key? key;
}
