import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Builds a different subtree per [SizeClass], falling back to the next
/// smaller builder when one is omitted (FE-RESP-02).
///
/// Keep in-progress input on the same [State] by lifting it, or by omitting
/// builders so the same compact tree is reused — this widget does not key
/// itself by size class (FE-RESP-03).
class ResponsiveBuilder extends StatelessWidget {
  /// Creates a builder. [compact] is required; [medium] and [expanded] fall
  /// back toward it.
  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  /// Layout used on [SizeClass.compact], and as the fallback for larger
  /// classes that have no builder of their own.
  final WidgetBuilder compact;

  /// Layout used on [SizeClass.medium]. Falls back to [compact].
  final WidgetBuilder? medium;

  /// Layout used on [SizeClass.expanded]. Falls back to [medium], then
  /// [compact].
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder builder = context.responsive(
      compact: compact,
      medium: medium,
      expanded: expanded,
    );
    return builder(context);
  }
}
