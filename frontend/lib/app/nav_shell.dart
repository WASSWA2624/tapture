import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_destination.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/app/widgets/offline_banner.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_viewport.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/context/presentation/context_maintenance.dart';
import 'package:tapture/features/projects/presentation/project_list_toolbar.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/records/presentation/records_list_view.dart';

/// The four-destination frame: bar on compact, rail on medium, rail plus a
/// list pane on expanded. [shell] keeps each branch's stack (FE-RESP-03).
/// The pane lists projects on Projects, and a record's siblings beside an
/// open record.
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
    final int index = shell.currentIndex;
    // Records keeps its list in the body; the pane holds the list only
    // beside an open record, so it never shows an empty column.
    final bool showPane =
        pane &&
        shellDestinations[index].hasList &&
        (shellDestinations[index].path != RoutePaths.records ||
            _openRecord(
                  GoRouterState.of(context).uri,
                  ref.watch(currentProjectProvider),
                ) !=
                null);
    final BorderSide hairline = BorderSide(
      color: context.colors.outline,
      width: Space.x0 / 2,
    );
    // The status line is the only title bar on every shell route.
    return ShellHeaderScope(
      ownsHeader: true,
      child: ContextMaintenance(
        child: Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SafeArea(bottom: false, child: StatusLine()),
              Expanded(
                // The header above already cleared the status bar. Pages below
                // must not see that inset again, or every page frame pads the
                // top twice (FE-RESP-08). The Builder reads the Scaffold body's
                // data, which no longer carries the keyboard inset; this
                // widget's own context would put it back, and every page would
                // shrink by the keyboard a second time.
                child: Builder(
                  builder: (BuildContext body) => MediaQuery.removePadding(
                    context: body,
                    removeTop: true,
                    child: SafeArea(
                      top: false,
                      child: AppListViewport(
                        header: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            ContextBar(
                              showsEmptyLevels:
                                  shellDestinations[index].path ==
                                  RoutePaths.captureRoot,
                            ),
                            const OfflineBanner(),
                          ],
                        ),
                        body: Row(
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
                                  inverted: _darkDesktopRail(context, ref),
                                ),
                              ),
                            if (showPane)
                              SizedBox(
                                width: Sizes.listPane,
                                child: _Pane(index: index),
                              ),
                            Expanded(
                              key: const ValueKey<String>('nav-body-slot'),
                              child: shell,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: rail ? null : _Bar(shell: shell),
        ),
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

  StatefulNavigationShell get shell => widget.shell;

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
            if (shellDestinations[index].path == RoutePaths.more) {
              // The popup owns its dismissal; selecting More must not reset
              // the current branch or discard the page under the menu.
              unawaited(_showMore());
            } else {
              shell.goBranch(index, initialLocation: true);
            }
          },
          destinations: <NavigationDestination>[
            for (int index = 0; index < shellDestinations.length; index++)
              NavigationDestination(
                key: shellDestinations[index].path == RoutePaths.more
                    ? _moreKey
                    : null,
                icon: _NavIcon(
                  index: index,
                  selected: false,
                  inverted: false,
                  compact: true,
                ),
                selectedIcon: _NavIcon(
                  index: index,
                  selected: true,
                  inverted: false,
                  compact: true,
                ),
                label:
                    shellDestinations[index].compactLabelFor(
                      Copy.of(context),
                    ) ??
                    shellDestinations[index].labelFor(Copy.of(context)),
                tooltip:
                    shellDestinations[index].compactLabelFor(
                      Copy.of(context),
                    ) ??
                    shellDestinations[index].labelFor(Copy.of(context)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMore() async {
    final GoRouter router = GoRouter.of(context);
    final RenderBox anchor =
        _moreKey.currentContext!.findRenderObject()! as RenderBox;
    await showAppOverflowActions(
      context,
      // Square like every other menu: the shared shape, no override.
      anchor: anchor.localToGlobal(Offset.zero) & anchor.size,
      items: <AppOverflowAction>[
        for (final ShellDestination destination in moreDestinations)
          AppOverflowAction(
            key: ValueKey<String>('nav-more-${destination.path}'),
            label: destination.labelFor(Copy.of(context)),
            icon: destination.icon,
            // The root popup can outlive the compact bar during rotation.
            onTap: () => router.go(destination.path),
          ),
      ],
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
        // A landscape phone with the keyboard open is shorter than the four
        // destinations; the rail scrolls rather than overflowing.
        scrollable: true,
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
              label: Text(shellDestinations[index].labelFor(Copy.of(context))),
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
    final _OpenRecord? open = _openRecord(
      GoRouterState.of(context).uri,
      ref.watch(currentProjectProvider),
    );
    return RepaintBoundary(
      key: const ValueKey<String>('nav-pane'),
      child: Material(
        color: context.colors.surface,
        clipBehavior: Clip.hardEdge,
        // In front: every list row paints an opaque fill that would
        // otherwise cover the pane's edge (FBK0000007).
        child: DecoratedBox(
          key: const ValueKey<String>('nav-pane-border'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(
                color: context.colors.outline,
                width: Space.x0 / 2,
              ),
            ),
          ),
          child: open != null
              ? RecordsListView(
                  projectId: open.projectId,
                  pane: true,
                  currentRecordId: open.recordId,
                  onOpen: (String id) => _openBeside(context, open, id),
                )
              : AppListViewport(
                  header: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      Space.x3,
                      Space.x1,
                      Space.x3,
                      Space.x2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_paneHasRows(ref)) ...<Widget>[
                          ProjectListActions.paneToolbar(context),
                          const SizedBox(height: Space.x2),
                        ],
                        const ProjectListToolbar(),
                      ],
                    ),
                  ),
                  body: const ProjectListView(filtered: true),
                ),
        ),
      ),
    );
  }
}

/// A record open in the body, so the pane lists its project's records
/// beside it (FE-RESP-05).
class _OpenRecord {
  const _OpenRecord({
    required this.projectId,
    required this.recordId,
    required this.inProject,
  });

  final String projectId;
  final String recordId;
  final bool inProject;
}

/// The record [uri] is showing, with the project it belongs to. The Records
/// destination uses the open project. A list with no record open returns
/// null, so the pane keeps the destination's own list.
_OpenRecord? _openRecord(Uri uri, String? currentProject) {
  final List<String> parts = uri.pathSegments;
  if (parts.length >= 2 && parts.first == 'records') {
    if (currentProject == null || currentProject.isEmpty) {
      return null;
    }
    return _OpenRecord(
      projectId: currentProject,
      recordId: parts[1],
      inProject: false,
    );
  }
  if (parts.length >= 4 && parts[0] == 'projects' && parts[2] == 'records') {
    return _OpenRecord(
      projectId: parts[1],
      recordId: parts[3],
      inProject: true,
    );
  }
  return null;
}

/// Opens [id] in the same branch the pane was opened from.
void _openBeside(BuildContext context, _OpenRecord open, String id) {
  final String location = open.inProject
      ? RoutePaths.projectRecord(open.projectId, id)
      : RoutePaths.record(id);
  if (GoRouterState.of(context).uri.path == location) {
    return;
  }
  context.go(location);
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
    this.compact = false,
  });

  final int index;
  final bool selected;
  final bool inverted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ShellDestination destination = shellDestinations[index];
    final IconData icon =
        (compact ? destination.compactIcon : null) ??
        (selected ? destination.selectedIcon : destination.icon);
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

/// The desktop rail is the dark panel in the light theme, except outdoor,
/// which keeps its own high-contrast rail. Read from the chosen mode, not
/// guessed from colours.
bool _darkDesktopRail(BuildContext context, WidgetRef ref) {
  final bool outdoor = ref.watch(themeModeProvider) == AppThemeMode.outdoor;
  return Theme.of(context).brightness == Brightness.light && !outdoor;
}
