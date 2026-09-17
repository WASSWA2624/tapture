import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';

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
    return Scaffold(
      body: Row(
        children: <Widget>[
          rail ? _Rail(shell: shell) : const SizedBox.shrink(),
          if (pane) Expanded(flex: 2, child: _Pane(index: shell.currentIndex)),
          Expanded(
            key: const ValueKey<String>('nav-body-slot'),
            flex: 3,
            child: shell,
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
    return NavigationBar(
      key: const ValueKey<String>('nav-bar'),
      selectedIndex: shell.currentIndex,
      onDestinationSelected: shell.goBranch,
      destinations: <NavigationDestination>[
        for (int index = 0; index < _destinations.length; index++)
          NavigationDestination(
            icon: _NavIcon(index: index, selected: false),
            selectedIcon: _NavIcon(index: index, selected: true),
            label: _destinations[index].label,
          ),
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: NavigationRail(
        key: const ValueKey<String>('nav-rail'),
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        labelType: NavigationRailLabelType.all,
        destinations: <NavigationRailDestination>[
          for (int index = 0; index < _destinations.length; index++)
            NavigationRailDestination(
              icon: _NavIcon(index: index, selected: false),
              selectedIcon: _NavIcon(index: index, selected: true),
              label: Text(_destinations[index].label),
            ),
        ],
      ),
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
      color: context.colors.surfaceVariant,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Text(_destinations[index].label),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.index, required this.selected});

  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final _Destination destination = _destinations[index];
    final IconData icon = selected
        ? destination.selectedIcon
        : destination.icon;
    return Icon(
      icon,
      key: ValueKey<String>('nav-icon-$index'),
      size: destination.dominant ? Space.x8 : Space.x6,
      color: destination.dominant ? context.colors.primary : null,
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.dominant = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool dominant;
}

const List<_Destination> _destinations = <_Destination>[
  _Destination(
    icon: Icons.work_outline,
    selectedIcon: Icons.work,
    label: Copy.navProjects,
  ),
  _Destination(
    icon: Icons.photo_camera_outlined,
    selectedIcon: Icons.photo_camera,
    label: Copy.navCapture,
    dominant: true,
  ),
  _Destination(
    icon: Icons.list_alt_outlined,
    selectedIcon: Icons.list_alt,
    label: Copy.navRecords,
  ),
  _Destination(
    icon: Icons.more_horiz,
    selectedIcon: Icons.more_horiz,
    label: Copy.navMore,
  ),
];
