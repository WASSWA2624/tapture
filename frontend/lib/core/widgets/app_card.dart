import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/elevation.dart';

/// Grouped-content card. Padding, radius and surface come from
/// [Elevation.surface]; the card is tappable only when [onTap] is set.
class AppCard extends StatelessWidget {
  /// Creates a card. [elevationLevel] is 0 (page) through 3 (dialog).
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevationLevel = 1,
  });

  /// Card body. This widget does not scroll.
  final Widget child;

  /// Insets around [child]. Defaults to [Space.x3] on every side.
  final EdgeInsets? padding;

  /// When set, the whole card is a 48dp tap target. Null is display-only.
  final VoidCallback? onTap;

  /// Surface depth passed to [Elevation.surface].
  final int elevationLevel;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = Elevation.surface(
      context,
      level: elevationLevel,
    );
    final BorderRadius radius = BorderRadius.circular(Radii.md);
    final EdgeInsets insets = padding ?? const EdgeInsets.all(Space.x3);
    final Widget body = Padding(padding: insets, child: child);
    final Widget interactive = onTap == null
        ? body
        : InkWell(onTap: onTap, child: body);
    final Widget painted = DecoratedBox(
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(width: double.infinity, child: interactive),
      ),
    );
    final Widget clipped = ClipRRect(borderRadius: radius, child: painted);
    if (onTap == null) {
      return clipped;
    }
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
          child: clipped,
        ),
      ),
    );
  }
}
