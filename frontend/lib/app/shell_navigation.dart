import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';

import 'route_paths.dart';
import 'shell_destination.dart';

/// Home tabs as a rail or a bar whose More menu contains only overflow.
class ShellNavigation extends StatelessWidget {
  /// Uses the existing route branches; capacity changes never navigate.
  const ShellNavigation({
    required this.shell,
    this.rail = false,
    this.inverted = false,
    super.key,
  });

  /// Navigation container retaining the project's working screen.
  final StatefulNavigationShell shell;

  /// Whether the shell has room for its vertical rail.
  final bool rail;

  /// Whether the rail uses the dark desktop surface in light mode.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    if (!rail) {
      return _Bar(shell: shell);
    }
    final AppColors colors = context.colors;
    final Color ink = inverted ? colors.surface : colors.onSurface;
    final Color selected = inverted ? AppColors.dark.primary : colors.primary;
    final TextStyle? style = Theme.of(context).textTheme.labelSmall;
    return RepaintBoundary(
      key: const ValueKey<String>('nav-rail'),
      child: NavigationRail(
        backgroundColor: inverted
            ? AppColors.dark.surfaceVariant
            : colors.surfaceVariant,
        selectedIndex: _selectedIndex(GoRouterState.of(context).uri),
        onDestinationSelected: (int index) =>
            _navigate(context, shell, navigationDestinations[index]),
        scrollable: true,
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: style?.copyWith(color: selected),
        unselectedLabelTextStyle: style?.copyWith(color: ink),
        destinations: <NavigationRailDestination>[
          for (final ShellDestination destination in navigationDestinations)
            NavigationRailDestination(
              icon: _NavIcon(destination: destination, inverted: inverted),
              selectedIcon: _NavIcon(
                destination: destination,
                selected: true,
                inverted: inverted,
              ),
              label: Text(destination.labelFor(Copy.of(context))),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  final GlobalKey _moreKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy copy = Copy.of(context);
    return RepaintBoundary(
      key: const ValueKey<String>('nav-bar'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.colors.outline, width: Space.x0 / 2),
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final List<double> widths = _labelWidths(context, copy);
            final int visible = _visibleCount(
              widths,
              constraints.maxWidth - MediaQuery.paddingOf(context).horizontal,
            );
            final List<ShellDestination> hidden = navigationDestinations
                .skip(visible)
                .toList(growable: false);
            final int selected = _selectedIndex(GoRouterState.of(context).uri);
            return NavigationBar(
              labelPadding: const EdgeInsetsDirectional.fromSTEB(
                Space.x2,
                Space.x1,
                Space.x2,
                0,
              ),
              selectedIndex: math.min(selected, visible),
              onDestinationSelected: (int index) {
                if (index == visible && hidden.isNotEmpty) {
                  // Opening or dismissing overflow keeps the current work screen.
                  unawaited(_showMore(hidden));
                } else {
                  _navigate(
                    context,
                    widget.shell,
                    navigationDestinations[index],
                  );
                }
              },
              destinations: <NavigationDestination>[
                for (final ShellDestination destination
                    in navigationDestinations.take(visible))
                  NavigationDestination(
                    key: ValueKey<String>('nav-tab-${destination.path}'),
                    icon: _NavIcon(destination: destination),
                    selectedIcon: _NavIcon(
                      destination: destination,
                      selected: true,
                    ),
                    label: destination.labelFor(copy),
                    tooltip: destination.labelFor(copy),
                  ),
                if (hidden.isNotEmpty)
                  NavigationDestination(
                    key: _moreKey,
                    icon: const Icon(AppIcons.moreHorizontal),
                    label: copy.navMoreMenu,
                    tooltip: copy.navMoreMenu,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showMore(List<ShellDestination> hidden) async {
    final GoRouter router = GoRouter.of(context);
    final RenderBox anchor =
        _moreKey.currentContext!.findRenderObject()! as RenderBox;
    await showAppOverflowActions(
      context,
      anchor: anchor.localToGlobal(Offset.zero) & anchor.size,
      items: <AppOverflowAction>[
        for (final ShellDestination destination in hidden)
          AppOverflowAction(
            key: ValueKey<String>('nav-more-${destination.path}'),
            label: destination.labelFor(Copy.of(context)),
            icon: destination.icon,
            // The menu may outlive this bar when the window becomes a rail.
            onTap: () => router.go(destination.path),
          ),
      ],
    );
  }
}

void _navigate(
  BuildContext context,
  StatefulNavigationShell shell,
  ShellDestination destination,
) {
  if (destination.path == RoutePaths.projects) {
    shell.goBranch(0);
  } else {
    // Templates and Settings share a branch but each tab opens its own screen.
    context.go(destination.path);
  }
}

int _selectedIndex(Uri uri) {
  int selected = 0;
  int longest = 0;
  for (int index = 0; index < navigationDestinations.length; index++) {
    final String path = navigationDestinations[index].path;
    if ((uri.path == path || uri.path.startsWith('$path/')) &&
        path.length > longest) {
      selected = index;
      longest = path.length;
    }
  }
  return selected;
}

List<double> _labelWidths(BuildContext context, LocalizedCopy copy) {
  final NavigationBarThemeData theme = NavigationBarTheme.of(context);
  final TextStyle inherited = DefaultTextStyle.of(context).style;
  // Match Material NavigationDestination's documented label-scaling cap.
  final TextPainter painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
    locale: Localizations.localeOf(context),
    maxLines: 1,
  );
  try {
    final List<double> widths = <double>[];
    for (final String label in <String>[
      for (final ShellDestination destination in navigationDestinations)
        destination.labelFor(copy),
      copy.navMoreMenu,
    ]) {
      double width = Sizes.minTapTarget;
      for (final Set<WidgetState> states in <Set<WidgetState>>[
        <WidgetState>{},
        <WidgetState>{WidgetState.selected},
      ]) {
        painter
          ..text = TextSpan(
            text: label,
            style: inherited.merge(
              theme.labelTextStyle?.resolve(states) ?? AppText.caption,
            ),
          )
          ..layout();
        width = math.max(width, painter.width.ceilToDouble() + Space.x4);
      }
      widths.add(width);
    }
    return widths;
  } finally {
    painter.dispose();
  }
}

int _visibleCount(List<double> widths, double available) {
  final int count = navigationDestinations.length;
  if (widths.take(count).reduce(math.max) * count <= available) {
    return count;
  }
  // NavigationBar gives each control equal width. Reserve a slot for More.
  for (int visible = count - 1; visible > 1; visible--) {
    if (math.max(widths.take(visible).reduce(math.max), widths.last) *
            (visible + 1) <=
        available) {
      return visible;
    }
  }
  return 1;
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.destination,
    this.selected = false,
    this.inverted = false,
  });

  final ShellDestination destination;
  final bool selected;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Icon(
      selected ? destination.selectedIcon : destination.icon,
      size: Space.x6,
      color: selected
          ? (inverted ? AppColors.dark.primary : colors.primary)
          : (inverted ? colors.surface : colors.onSurface),
    );
  }
}
