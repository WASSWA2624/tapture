import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/dimensions.dart';

import 'breakpoints.dart';

/// Two controls that stack on a phone and share one row from medium width
/// up, such as two selects or two saves (FE-RESP-02).
///
/// On [SizeClass.compact] [start] sits above [end], both full width, unless
/// [stacksOnCompact] is false. On [SizeClass.medium] and
/// [SizeClass.expanded] they sit side by side, top-aligned, splitting the
/// width [startFlex] to [endFlex]; with [matchesHeights] both sides take the
/// taller side's height. [start] is on the reading side, so it is on the
/// right under a right-to-left locale (FE-L10N-05).
class ResponsivePair extends StatelessWidget {
  /// Creates a pair. [gap] separates the two in either direction.
  const ResponsivePair({
    super.key,
    required this.start,
    required this.end,
    this.startFlex = 1,
    this.endFlex = 1,
    this.gap = Space.x3,
    this.stacksOnCompact = true,
    this.matchesHeights = false,
  }) : assert(startFlex > 0 && endFlex > 0, 'each side needs a share');

  /// First in reading order: above on compact, on the start side otherwise.
  final Widget start;

  /// Second in reading order: below on compact, on the end side otherwise.
  final Widget end;

  /// [start]'s share of the row's width.
  final int startFlex;

  /// [end]'s share of the row's width.
  final int endFlex;

  /// Space between the two, below [start] or beside it.
  final double gap;

  /// When false, the pair shares one row on [SizeClass.compact] too, as two
  /// short controls such as a pair of saves do (FBK0000158).
  final bool stacksOnCompact;

  /// When true, a shared row gives both sides the taller side's height, so
  /// two buttons stay level when one label wraps.
  final bool matchesHeights;

  @override
  Widget build(BuildContext context) {
    if (stacksOnCompact && context.sizeClass == SizeClass.compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          start,
          SizedBox(height: gap),
          end,
        ],
      );
    }
    final Widget row = Row(
      crossAxisAlignment: matchesHeights
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: startFlex, child: start),
        SizedBox(width: gap),
        Expanded(flex: endFlex, child: end),
      ],
    );
    return matchesHeights ? IntrinsicHeight(child: row) : row;
  }
}
