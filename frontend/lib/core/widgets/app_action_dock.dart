import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/dimensions.dart';

import 'responsive/content_constraint.dart';
import 'responsive/viewport_metrics.dart';

/// Keeps existing actions reachable without consuming the whole short viewport.
class AppActionDock extends StatelessWidget {
  /// Creates the shared page, selection-bar and recording-footer viewport.
  const AppActionDock({
    super.key,
    required this.child,
    this.maxHeight,
    this.compact = false,
    this.inset = true,
  });

  /// Existing controls; their order and callbacks remain with the caller.
  final Widget child;

  /// Explicit budget from a bounded page; otherwise half the visible height.
  final double? maxHeight;

  /// Uses the compact header's top inset while preserving touch targets.
  final bool compact;

  /// Insets controls even on edge-to-edge list pages.
  final bool inset;

  /// Reserves the shared action share of an owning page or pane's height.
  static double heightBudget(double availableHeight) =>
      availableHeight * _heightShare;

  @override
  Widget build(BuildContext context) {
    final double visible =
        context.viewportSize.height - MediaQuery.viewInsetsOf(context).bottom;
    final double budget = maxHeight ?? heightBudget(visible);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: budget.clamp(0, double.infinity).toDouble(),
      ),
      child: SingleChildScrollView(
        primary: false,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: inset ? ContentConstraint.gutter(context) : 0,
              vertical: Space.x2,
            ).copyWith(top: compact ? Space.x1 : Space.x2),
            child: ContentConstraint(child: child),
          ),
        ),
      ),
    );
  }
}

const double _heightShare = 0.5;
