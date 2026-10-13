import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/dimensions.dart';

import 'breakpoints.dart';

/// Centres [child] and caps its width so text and forms do not stretch
/// edge to edge on expanded windows (FE-RESP-04).
class ContentConstraint extends StatelessWidget {
  /// Creates a readable column. [maxWidth] defaults to a measure of reading
  /// comfort, not a breakpoint (FE-RESP-01).
  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = _readableMax,
  });

  /// The subtree that stays readable.
  final Widget child;

  /// The cap, in logical pixels. A screen may pass a tighter one.
  final double maxWidth;

  /// Consistent side insets for readable pages, forms and action docks.
  static double gutter(BuildContext context) => context.responsive(
    compact: Space.x4,
    medium: Space.x4,
    expanded: Space.x5,
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// Default readable column. Below the expanded breakpoint so it is not a
/// window-width token (FE-RESP-01).
const double _readableMax = 720;
