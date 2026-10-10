import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_back_navigation.dart';
import 'package:tapture/app/shell_destination.dart';
import 'package:tapture/app/shell_navigation.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/app/widgets/offline_banner.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/widgets/app_list_viewport.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/context/presentation/context_maintenance.dart';
import 'package:tapture/features/projects/presentation/project_list_toolbar.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/records/presentation/records_list_view.dart';

/// The project frame: bar on compact, rail on medium, rail plus a
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
    return ShellBackNavigation(
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

class _Chrome extends ConsumerWidget {
  const _Chrome({required this.shell, required this.rail, required this.pane});

  final StatefulNavigationShell shell;
  final bool rail;
  final bool pane;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = shell.currentIndex;
    final Uri location = GoRouterState.of(context).uri;
    // Keep capture focused. The records pane appears only beside a record.
    final bool showPane =
        pane &&
        shellDestinations[index].hasList &&
        !RoutePaths.isProjectCapture(location.path) &&
        (!location.path.contains('/records') || _openRecord(location) != null);
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
                            if (GoRouterState.of(
                                  context,
                                ).pathParameters.containsKey('projectId') &&
                                !RoutePaths.isProjectCapture(location.path))
                              const ContextBar(),
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
                                child: ShellNavigation(
                                  rail: true,
                                  shell: shell,
                                  inverted: _darkDesktopRail(context, ref),
                                ),
                              ),
                            if (showPane)
                              const SizedBox(
                                width: Sizes.listPane,
                                child: _Pane(),
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
          bottomNavigationBar: rail ? null : ShellNavigation(shell: shell),
        ),
      ),
    );
  }
}

class _Pane extends ConsumerWidget {
  const _Pane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _OpenRecord? open = _openRecord(GoRouterState.of(context).uri);
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
  const _OpenRecord({required this.projectId, required this.recordId});

  final String projectId;
  final String recordId;
}

/// The record [uri] is showing inside its owning project.
_OpenRecord? _openRecord(Uri uri) {
  final List<String> parts = uri.pathSegments;
  if (parts.length >= 4 && parts[0] == 'projects' && parts[2] == 'records') {
    return _OpenRecord(projectId: parts[1], recordId: parts[3]);
  }
  return null;
}

/// Opens [id] in the same branch the pane was opened from.
void _openBeside(BuildContext context, _OpenRecord open, String id) {
  final String location = RoutePaths.projectRecord(open.projectId, id);
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

/// The desktop rail is the dark panel in the light theme, except outdoor,
/// which keeps its own high-contrast rail. Read from the chosen mode, not
/// guessed from colours.
bool _darkDesktopRail(BuildContext context, WidgetRef ref) {
  final bool outdoor = ref.watch(themeModeProvider) == AppThemeMode.outdoor;
  return Theme.of(context).brightness == Brightness.light && !outdoor;
}
