import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/app/widgets/offline_banner.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

/// The four-destination frame: bar on compact, rail on medium, rail plus a
/// list pane on expanded. [shell] keeps each branch's stack (FE-RESP-03).
class NavShell extends StatelessWidget {
  /// Creates the shell around [shell].
  const NavShell({required this.shell, super.key});

  /// Branch container from [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      compact: (BuildContext _) {
        return _Chrome(shell: shell, rail: false, pane: false);
      },
      medium: (BuildContext _) {
        return _Chrome(shell: shell, rail: true, pane: false);
      },
      expanded: (BuildContext _) {
        return _Chrome(shell: shell, rail: true, pane: true);
      },
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({required this.shell, required this.rail, required this.pane});

  final StatefulNavigationShell shell;
  final bool rail;
  final bool pane;

  @override
  Widget build(BuildContext context) {
    final bool showPane = pane && _destinations[shell.currentIndex].hasList;
    final BorderSide hairline = BorderSide(
      color: context.colors.outline,
      width: Space.x0 / 2,
    );
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[StatusLine(), OfflineBanner()],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Row(
                children: <Widget>[
                  if (rail)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: showPane
                            ? null
                            : BorderDirectional(end: hairline),
                      ),
                      child: _Rail(
                        shell: shell,
                        inverted: _darkDesktopRail(context),
                      ),
                    ),
                  if (showPane)
                    SizedBox(
                      width: Sizes.listPane,
                      child: _Pane(index: shell.currentIndex),
                    ),
                  Expanded(
                    key: const ValueKey<String>('nav-body-slot'),
                    child: shell,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: rail ? null : _Bar(shell: shell),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.colors.outline, width: Space.x0 / 2),
        ),
      ),
      child: NavigationBar(
        key: const ValueKey<String>('nav-bar'),
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: <NavigationDestination>[
          for (int index = 0; index < _destinations.length; index++)
            NavigationDestination(
              icon: _NavIcon(index: index, selected: false, inverted: false),
              selectedIcon: _NavIcon(
                index: index,
                selected: true,
                inverted: false,
              ),
              label: _destinations[index].label,
            ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.shell, required this.inverted});

  final StatefulNavigationShell shell;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color railInk = inverted ? colors.surface : colors.onSurface;
    return NavigationRail(
      key: const ValueKey<String>('nav-rail'),
      backgroundColor: inverted
          ? AppColors.dark.surface
          : colors.surfaceVariant,
      selectedIndex: shell.currentIndex,
      onDestinationSelected: shell.goBranch,
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: AppText.caption.copyWith(color: colors.primary),
      unselectedLabelTextStyle: AppText.caption.copyWith(color: railInk),
      destinations: <NavigationRailDestination>[
        for (int index = 0; index < _destinations.length; index++)
          NavigationRailDestination(
            icon: _NavIcon(index: index, selected: false, inverted: inverted),
            selectedIcon: _NavIcon(
              index: index,
              selected: true,
              inverted: inverted,
            ),
            label: Text(_destinations[index].label),
          ),
      ],
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey<String>('nav-pane'),
      color: context.colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            end: BorderSide(color: context.colors.outline, width: Space.x0 / 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.x4,
                Space.x4,
                Space.x4,
                Space.x2,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _destinations[index].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.x3,
                Space.x0,
                Space.x3,
                Space.x2,
              ),
              child: AppSearchField(hint: Copy.search, onChanged: (_) {}),
            ),
            Expanded(
              child: AppEmptyState(
                icon: _destinations[index].icon,
                headline: Copy.emptyHeadline,
                message: Copy.emptyMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.index,
    required this.selected,
    required this.inverted,
  });

  final int index;
  final bool selected;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final _Destination destination = _destinations[index];
    final IconData icon = selected
        ? destination.selectedIcon
        : destination.icon;
    final AppColors colors = context.colors;
    return Icon(
      icon,
      key: ValueKey<String>('nav-icon-$index'),
      size: destination.dominant ? Space.x8 : Space.x6,
      color: destination.dominant || selected
          ? colors.primary
          : (inverted ? colors.surface : colors.onSurface),
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.dominant = false,
    this.hasList = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool dominant;
  final bool hasList;
}

bool _darkDesktopRail(BuildContext context) {
  final AppColors colors = context.colors;
  final bool outdoor =
      colors.surface == AppColors.outdoor.surface &&
      colors.onSurface == AppColors.outdoor.onSurface &&
      colors.outline == AppColors.outdoor.outline;
  return Theme.of(context).brightness == Brightness.light && !outdoor;
}

const List<_Destination> _destinations = <_Destination>[
  _Destination(
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
    label: Copy.navProjects,
    hasList: true,
  ),
  _Destination(
    icon: Icons.photo_camera_outlined,
    selectedIcon: Icons.photo_camera,
    label: Copy.navCapture,
    dominant: true,
  ),
  _Destination(
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
    label: Copy.navRecords,
    hasList: true,
  ),
  _Destination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: Copy.navMore,
  ),
];
