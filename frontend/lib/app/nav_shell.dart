import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/feedback_host.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/app/widgets/offline_banner.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
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
    return FeedbackHost(
      child: ResponsiveBuilder(
        compact: (BuildContext _) {
          return _Chrome(shell: shell, rail: false, pane: false);
        },
        medium: (BuildContext _) {
          return _Chrome(shell: shell, rail: true, pane: false);
        },
        expanded: (BuildContext _) {
          return _Chrome(shell: shell, rail: true, pane: true);
        },
      ),
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
                OfflineBanner(),
                _NavCountLive(),
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
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            shell.goBranch(index, initialLocation: index == shell.currentIndex);
          },
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
                tooltip: _destinationTooltip(ref, _destinations[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends ConsumerWidget {
  const _Rail({required this.shell, required this.inverted});

  final StatefulNavigationShell shell;
  final bool inverted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          shell.goBranch(index, initialLocation: index == shell.currentIndex);
        },
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: AppText.caption.copyWith(color: selected),
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
              label: Semantics(
                label: _destinationTooltip(ref, _destinations[index]),
                excludeSemantics: true,
                child: Text(_destinations[index].label),
              ),
            ),
        ],
      ),
    );
  }
}

String _destinationTooltip(WidgetRef ref, _Destination destination) {
  final Provider<int>? count = destination.count;
  if (count == null) {
    return destination.label;
  }
  final int n = ref.watch(count);
  if (n <= 0) {
    return destination.label;
  }
  return '${destination.label}, ${Copy.navProjectsCount(n)}';
}

class _Pane extends ConsumerWidget {
  const _Pane({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool projects = index == 0;
    final String query = ref.watch(projectListSearchQueryProvider);
    return RepaintBoundary(
      key: const ValueKey<String>('nav-pane'),
      child: Material(
        color: context.colors.surface,
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
                  Space.x4,
                  Space.x3,
                  Space.x2,
                ),
                child: AppSearchField(
                  hint: Copy.search,
                  text: projects ? query : null,
                  onChanged: projects
                      ? ref.read(projectListSearchQueryProvider.notifier).set
                      : (_) {},
                ),
              ),
              Expanded(
                child: projects
                    ? const ProjectListView(filtered: true)
                    : AppEmptyState(
                        icon: _destinations[index].icon,
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

/// Announces the Projects count when it changes (FE-A11Y-07). Lives in
/// the chrome, not inside the bar or rail, so MergeSemantics cannot
/// swallow the live region.
class _NavCountLive extends ConsumerWidget {
  const _NavCountLive();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(projectNavCountProvider);
    return Semantics(
      key: const ValueKey<String>('nav-count-live'),
      liveRegion: count > 0,
      container: true,
      label: count > 0 ? Copy.navProjectsCount(count) : '',
      child: const SizedBox.shrink(),
    );
  }
}

class _NavIcon extends ConsumerWidget {
  const _NavIcon({
    required this.index,
    required this.selected,
    required this.inverted,
  });

  final int index;
  final bool selected;
  final bool inverted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _Destination destination = _destinations[index];
    final IconData icon = selected
        ? destination.selectedIcon
        : destination.icon;
    final AppColors colors = context.colors;
    final Color accent = inverted ? AppColors.dark.primary : colors.primary;
    final Widget mark = Icon(
      icon,
      key: ValueKey<String>('nav-icon-$index'),
      size: destination.dominant ? Space.x8 : Space.x6,
      color: selected ? accent : (inverted ? colors.surface : colors.onSurface),
    );
    final Provider<int>? countListenable = destination.count;
    if (countListenable == null) {
      return mark;
    }
    final int count = ref.watch(countListenable);
    if (count <= 0) {
      return mark;
    }
    final AppColors palette = inverted ? AppColors.dark : colors;
    return Semantics(
      container: true,
      liveRegion: true,
      label: Copy.navProjectsCount(count),
      excludeSemantics: true,
      child: Badge(
        alignment: AlignmentDirectional.topEnd,
        backgroundColor: palette.primary,
        textColor: palette.onPrimary,
        largeSize: Space.x4,
        padding: const EdgeInsets.symmetric(horizontal: Space.x1),
        label: Text(
          Copy.navProjectsCountBadge(count),
          maxLines: 1,
          textScaler: TextScaler.noScaling,
        ),
        child: mark,
      ),
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
    this.count,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool dominant;
  final bool hasList;

  /// Live count this destination shows on its icon. Null means no badge.
  final Provider<int>? count;
}

bool _darkDesktopRail(BuildContext context) {
  final AppColors colors = context.colors;
  final bool outdoor =
      colors.surface == AppColors.outdoor.surface &&
      colors.onSurface == AppColors.outdoor.onSurface &&
      colors.outline == AppColors.outdoor.outline;
  return Theme.of(context).brightness == Brightness.light && !outdoor;
}

final List<_Destination> _destinations = <_Destination>[
  _Destination(
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: Copy.navProjects,
    hasList: true,
    count: projectNavCountProvider,
  ),
  const _Destination(
    icon: Icons.photo_camera_outlined,
    selectedIcon: Icons.photo_camera,
    label: Copy.navCapture,
    dominant: true,
  ),
  const _Destination(
    icon: Icons.list_alt_outlined,
    selectedIcon: Icons.list_alt,
    label: Copy.navRecords,
    hasList: true,
  ),
  const _Destination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: Copy.navMore,
  ),
];
