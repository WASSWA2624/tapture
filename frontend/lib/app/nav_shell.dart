import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/shell_destination.dart';
import 'package:tapture/app/shell_title.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/app/widgets/offline_banner.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/context/presentation/context_maintenance.dart';
import 'package:tapture/features/projects/presentation/project_list_toolbar.dart';
import 'package:tapture/features/projects/projects.dart';

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

class _Chrome extends ConsumerWidget {
  const _Chrome({required this.shell, required this.rail, required this.pane});

  final StatefulNavigationShell shell;
  final bool rail;
  final bool pane;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool ownsHeader =
        ShellTitle.header(ref, GoRouterState.of(context).uri) != null;
    final bool showPane = pane && shellDestinations[shell.currentIndex].hasList;
    final BorderSide hairline = BorderSide(
      color: context.colors.outline,
      width: Space.x0 / 2,
    );
    return ShellHeaderScope(
      ownsHeader: ownsHeader,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  StatusLine(),
                  ContextBar(),
                  ContextMaintenance(),
                  OfflineBanner(),
                ],
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
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey<String>('nav-bar'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.colors.outline, width: Space.x0 / 2),
          ),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (int index) {
            shell.goBranch(index, initialLocation: true);
          },
          destinations: <NavigationDestination>[
            for (int index = 0; index < shellDestinations.length; index++)
              NavigationDestination(
                icon: _NavIcon(index: index, selected: false, inverted: false),
                selectedIcon: _NavIcon(
                  index: index,
                  selected: true,
                  inverted: false,
                ),
                label: shellDestinations[index].label,
                tooltip: shellDestinations[index].label,
              ),
          ],
        ),
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
    final Color selected = inverted ? AppColors.dark.primary : colors.primary;
    return RepaintBoundary(
      key: const ValueKey<String>('nav-rail'),
      child: NavigationRail(
        backgroundColor: inverted
            ? AppColors.dark.surfaceVariant
            : colors.surfaceVariant,
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (int index) {
          shell.goBranch(index, initialLocation: true);
        },
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: AppText.caption.copyWith(color: selected),
        unselectedLabelTextStyle: AppText.caption.copyWith(color: railInk),
        destinations: <NavigationRailDestination>[
          for (int index = 0; index < shellDestinations.length; index++)
            NavigationRailDestination(
              icon: _NavIcon(index: index, selected: false, inverted: inverted),
              selectedIcon: _NavIcon(
                index: index,
                selected: true,
                inverted: inverted,
              ),
              label: Text(shellDestinations[index].label),
            ),
        ],
      ),
    );
  }
}

class _Pane extends ConsumerWidget {
  const _Pane({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool projects = index == 0;
    return RepaintBoundary(
      key: const ValueKey<String>('nav-pane'),
      child: Material(
        color: context.colors.surface,
        clipBehavior: Clip.hardEdge,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(
                color: context.colors.outline,
                width: Space.x0 / 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  Space.x3,
                  Space.x1,
                  Space.x3,
                  Space.x2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (projects && _paneHasRows(ref)) ...<Widget>[
                      ProjectListActions.paneToolbar(context, ref),
                      const SizedBox(height: Space.x2),
                    ],
                    if (projects) const ProjectListToolbar(),
                  ],
                ),
              ),
              Expanded(
                child: projects
                    ? const ProjectListView(filtered: true)
                    : AppEmptyState(
                        icon: shellDestinations[index].icon,
                        headline: Copy.emptyHeadline,
                        message: Copy.emptyMessage,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _paneHasRows(WidgetRef ref) {
  return switch (ref.watch(projectListFilteredProvider)) {
    AsyncData(:final value) => value.isNotEmpty,
    _ => false,
  };
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
    final ShellDestination destination = shellDestinations[index];
    final IconData icon = selected
        ? destination.selectedIcon
        : destination.icon;
    final AppColors colors = context.colors;
    final Color accent = inverted ? AppColors.dark.primary : colors.primary;
    return Icon(
      icon,
      key: ValueKey<String>('nav-icon-$index'),
      size: destination.dominant ? Space.x8 : Space.x6,
      color: selected ? accent : (inverted ? colors.surface : colors.onSurface),
    );
  }
}

bool _darkDesktopRail(BuildContext context) {
  final AppColors colors = context.colors;
  final bool outdoor =
      colors.surface == AppColors.outdoor.surface &&
      colors.onSurface == AppColors.outdoor.onSurface &&
      colors.outline == AppColors.outdoor.outline;
  return Theme.of(context).brightness == Brightness.light && !outdoor;
}
