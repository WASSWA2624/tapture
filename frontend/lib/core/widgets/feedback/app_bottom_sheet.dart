import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/elevation.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page_layout.dart';
import 'package:tapture/core/widgets/app_page_layout_scope.dart';
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
    this.contentSized = false,
    this.embedded = false,
    this.layout = AppPageLayout.essentials,
  });

  /// Heading; also the semantic name of the sheet (FE-A11Y-02).
  final String title;

  /// Body. Lists that need a bounded viewport should expand inside this.
  final Widget child;

  /// When true, this is the expanded-layout side panel.
  final bool sidePanel;

  /// Shrink-wraps short content and scrolls when the keyboard or text scale
  /// needs more than the sheet cap.
  final bool contentSized;

  /// When true, the presenting modal owns the surface, so this sheet does
  /// not paint a second rounded container.
  final bool embedded;

  /// Sheets select their own composition instead of inheriting a page's.
  final AppPageLayout layout;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final BorderRadius radius = sidePanel
        ? BorderRadius.circular(Radii.md)
        : const BorderRadius.vertical(top: Radius.circular(Radii.lg));
    final BoxDecoration surface = Elevation.surface(context, level: 2);
    final BorderSide outline = switch (surface.border) {
      final Border border => border.top,
      _ => BorderSide(color: colors.outline, width: Space.x0 / 2),
    };
    final Widget body = SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: contentSized ? MainAxisSize.min : MainAxisSize.max,
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
            Flexible(
              fit: contentSized ? FlexFit.loose : FlexFit.tight,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth < _readableWidth
                      ? constraints.maxWidth
                      : _readableWidth;
                  return SizedBox(
                    width: width,
                    height: contentSized ? null : constraints.maxHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      // A short sheet ends under its content, not at the cap.
                      heightFactor: contentSized ? 1 : null,
                      child: DefaultTextStyle(
                        style: AppText.body.copyWith(color: colors.onSurface),
                        child: contentSized
                            ? SingleChildScrollView(child: child)
                            : child,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (embedded) {
      return AppPageLayoutScope(layout: layout, child: body);
    }
    return Material(
      color: surface.color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius, side: outline),
      child: AppPageLayoutScope(layout: layout, child: body),
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
  bool contentSized = false,
  AppPageLayout? layout,
}) {
  // Compact pages carry their density into overlays; other callers keep the
  // existing default unless they explicitly select a sheet composition.
  final AppPageLayout effective =
      layout ??
      (AppPageLayoutScope.of(context) == AppPageLayout.compact
          ? AppPageLayout.compact
          : AppPageLayout.essentials);
  if (context.sizeClass == SizeClass.expanded) {
    return _showSidePanel<T>(
      context,
      title: title,
      builder: builder,
      contentSized: contentSized,
      layout: effective,
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // AppBottomSheet draws the one handle; the theme's would be a second.
    showDragHandle: false,
    backgroundColor: context.colors.surface,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (BuildContext sheetContext) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // As tall as the sheet, so the scrim shows above a short one.
          return Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * _sheetFraction,
              ),
              child: AppBottomSheet(
                title: title,
                contentSized: contentSized,
                embedded: true,
                layout: effective,
                child: builder(sheetContext),
              ),
            ),
          );
        },
      );
    },
  );
}

/// The one filter sheet every list's search field opens from its filter
/// button (FBK0000003): the list's facets, then a Clear filters action that
/// runs [onClear] and closes the sheet.
///
/// [facets] rebuilds with the caller's state, so a choice made in the sheet
/// shows at once.
Future<void> showAppFilterSheet(
  BuildContext context, {
  required String title,
  required WidgetBuilder facets,
  required VoidCallback onClear,
  AppPageLayout layout = AppPageLayout.essentials,
}) {
  return showAppSheet<void>(
    context,
    title: title,
    contentSized: true,
    layout: layout,
    builder: (BuildContext sheetContext) {
      final LocalizedCopy localCopy = Copy.of(sheetContext);

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.x3,
          Space.x0,
          Space.x3,
          Space.x3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            facets(sheetContext),
            const SizedBox(height: Space.x3),
            AppButton(
              key: const ValueKey<String>('filter-sheet-clear'),
              label: localCopy.searchClearFilters,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () {
                onClear();
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<T?> _showSidePanel<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  bool contentSized = false,
  AppPageLayout layout = AppPageLayout.essentials,
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
                contentSized: contentSized,
                layout: layout,
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
