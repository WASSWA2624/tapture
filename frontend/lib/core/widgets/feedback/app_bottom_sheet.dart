import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/elevation.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';

/// Shared sheet chrome: drag handle, title, scrollable body, safe area.
///
/// [showAppSheet] presents this as a bottom sheet, or as a side panel on
/// expanded layouts (FE-CONS-05).
class AppBottomSheet extends StatelessWidget {
  /// Creates sheet chrome around [child]. [sidePanel] drops the handle.
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.sidePanel = false,
  });

  /// Heading; also the semantic name of the sheet (FE-A11Y-02).
  final String title;

  /// Body. Lists that need a bounded viewport should expand inside this.
  final Widget child;

  /// When true, this is the expanded-layout side panel.
  final bool sidePanel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final BorderRadius radius = sidePanel
        ? BorderRadius.zero
        : const BorderRadius.vertical(top: Radius.circular(Radii.lg));
    final BoxDecoration surface = Elevation.surface(context, level: 2);
    final BorderSide outline = switch (surface.border) {
      final Border border => border.top,
      _ => BorderSide(color: colors.outline, width: Space.x0 / 2),
    };
    return Material(
      color: surface.color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius, side: outline),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: <Widget>[
              if (!sidePanel) const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.x3,
                  Space.x2,
                  Space.x3,
                  Space.x2,
                ),
                child: Semantics(
                  header: true,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      title,
                      style: AppText.title.copyWith(color: colors.onSurface),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double width = constraints.maxWidth < _readableWidth
                        ? constraints.maxWidth
                        : _readableWidth;
                    return SizedBox(
                      width: width,
                      height: constraints.maxHeight,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: DefaultTextStyle(
                          style: AppText.body.copyWith(color: colors.onSurface),
                          child: child,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches [ContentConstraint]'s readable column without loosening height.
const double _readableWidth = 720;

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: Space.x2),
        child: SizedBox(
          width: Space.x12,
          height: Space.x1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.outline,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a bottom sheet, or a side panel when the window is expanded.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  if (context.sizeClass == SizeClass.expanded) {
    return _showSidePanel<T>(context, title: title, builder: builder);
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    builder: (BuildContext sheetContext) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * _sheetFraction,
              ),
              child: AppBottomSheet(title: title, child: builder(sheetContext)),
            ),
          );
        },
      );
    },
  );
}

Future<T?> _showSidePanel<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    transitionDuration: reduceMotion
        ? Duration.zero
        : AppConstants.motion.medium,
    pageBuilder:
        (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SizedBox(
              width: Space.x12 * 8,
              height: double.infinity,
              child: AppBottomSheet(
                title: title,
                sidePanel: true,
                child: builder(dialogContext),
              ),
            ),
          );
        },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
  );
}

/// Fraction of the overlay a compact or medium sheet may occupy.
const double _sheetFraction = 0.75;
