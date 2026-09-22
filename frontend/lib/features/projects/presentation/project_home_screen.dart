import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/context/presentation/context_providers.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'current_project.dart';
import 'project_archive_action.dart';
import 'project_delete_action.dart';
import 'project_duplicate_action.dart';
import 'project_open_externally_action.dart';

/// Open-project home: what to do next, with one primary capture action.
class ProjectHomeScreen extends ConsumerWidget {
  /// Creates the open-project home.
  const ProjectHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? details = ref.watch(currentProjectDetailsProvider);
    final AsyncValue<ProjectHomeView?> value = ref.watch(projectHomeProvider);
    final ProjectHomeView? view = value.asData?.value;
    return AppPage(
      key: const ValueKey<String>('route-project'),
      title: details?.name ?? Copy.navProjects,
      showAppBar: false,
      overflow: view == null
          ? const <AppOverflowAction>[]
          : _projectHomeMenu(context, ref, view),
      scrollable: false,
      footer: view == null
          ? null
          : AppPrimaryAction(
              label: Copy.continueCapturing,
              onPressed: () => context.go(_capture(view.project.id)),
            ),
      body: AsyncValueView<ProjectHomeView?>(
        value: value,
        isEmpty: (ProjectHomeView? loaded) => loaded == null,
        empty: () => AppEmptyState(
          icon: Icons.folder_open_outlined,
          headline: Copy.homeEmptyHeadline,
          message: Copy.homeEmptyMessage,
          actionLabel: Copy.navProjects,
          onAction: () => context.go(_projectsRoot),
        ),
        onRetry: () {
          ref.invalidate(projectListProvider);
          ref.invalidate(projectHomeCountsProvider);
        },
        data: (ProjectHomeView? loaded) => _HomeBody(view: loaded!),
      ),
    );
  }
}

/// Project, pinned context and pending counts for the home. Derived, never
/// stored (FE-STATE-06).
typedef ProjectHomeView = ({
  Project project,
  String context,
  ProjectHomeCounts counts,
});

/// Pinned context label on the home header from the open project context.
final Provider<String> projectHomeContextProvider = Provider<String>((Ref ref) {
  final AsyncValue<ContextState> value = ref.watch(openProjectContextProvider);
  return contextStatusLabel(value.asData?.value ?? const ContextState());
});

/// Pending Review, Process, Export and Share counts for the open project.
final StreamProvider<ProjectHomeCounts> projectHomeCountsProvider =
    StreamProvider<ProjectHomeCounts>((Ref ref) {
      final String? id = ref.watch(currentProjectProvider);
      if (id == null) {
        return Stream<ProjectHomeCounts>.value(emptyProjectHomeCounts);
      }
      return ref.watch(projectRepositoryProvider).watchHome(id);
    }, retry: (int _, Object _) => null);

/// Combined home snapshot. Empty when no project is open; loading and
/// failure follow the list or the counts watch.
final Provider<AsyncValue<ProjectHomeView?>> projectHomeProvider =
    Provider<AsyncValue<ProjectHomeView?>>((Ref ref) {
      final Project? details = ref.watch(currentProjectDetailsProvider);
      final AsyncValue<List<ProjectListRow>> list = ref.watch(
        projectListProvider,
      );
      final AsyncValue<ProjectHomeCounts> counts = ref.watch(
        projectHomeCountsProvider,
      );
      final String context = ref.watch(projectHomeContextProvider);
      if (details == null) {
        return list.when(
          data: (List<ProjectListRow> _) {
            return const AsyncData<ProjectHomeView?>(null);
          },
          error: AsyncError<ProjectHomeView?>.new,
          loading: () => const AsyncLoading<ProjectHomeView?>(),
        );
      }
      return counts.when(
        data: (ProjectHomeCounts loaded) {
          return AsyncData<ProjectHomeView?>((
            project: details,
            context: context,
            counts: loaded,
          ));
        },
        error: AsyncError<ProjectHomeView?>.new,
        loading: () => const AsyncLoading<ProjectHomeView?>(),
      );
    });

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.view});

  final ProjectHomeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectHomeCounts counts = view.counts;
    final bool shellOwns = ShellHeaderScope.ownsHeaderOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!shellOwns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Text(view.project.name, style: AppText.title)),
                AppOverflowMenu(items: _projectHomeMenu(context, ref, view)),
              ],
            ),
          if (!shellOwns) const SizedBox(height: Space.x1),
          Text(view.context, style: AppText.caption),
          const SizedBox(height: Space.x4),
          ..._countRows(context, counts),
        ],
      ),
    );
  }

  List<Widget> _countRows(BuildContext context, ProjectHomeCounts counts) {
    final String projectId = view.project.id;
    final List<Widget> cards = <Widget>[
      _CountCard(
        cardKey: const ValueKey<String>('home-review'),
        label: Copy.homeReview,
        count: counts.review,
        semanticLabel: Copy.homeReviewPending(counts.review),
        onTap: () => unawaited(context.push(_reviewList(projectId))),
      ),
      _CountCard(
        cardKey: const ValueKey<String>('home-process'),
        label: Copy.homeProcess,
        count: counts.process,
        semanticLabel: Copy.homeProcessPending(counts.process),
        onTap: () => unawaited(context.push(_processList(projectId))),
      ),
      _CountCard(
        cardKey: const ValueKey<String>('home-export'),
        label: Copy.homeExport,
        count: counts.toExport,
        semanticLabel: Copy.homeExportPending(counts.toExport),
        onTap: () => unawaited(context.push(_exportList(projectId))),
      ),
      _CountCard(
        cardKey: const ValueKey<String>('home-share'),
        label: Copy.homeShare,
        count: counts.toShare,
        semanticLabel: Copy.homeSharePending(counts.toShare),
        onTap: () => unawaited(context.push(_shareList(projectId))),
      ),
    ];
    final int columns = context.sizeClass == SizeClass.compact ? 2 : 4;
    return <Widget>[
      for (int row = 0; row < cards.length; row += columns) ...<Widget>[
        if (row > 0) const SizedBox(height: Space.x2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int column = 0; column < columns; column++) ...<Widget>[
              if (column > 0) const SizedBox(width: Space.x2),
              Expanded(child: cards[row + column]),
            ],
          ],
        ),
      ],
    ];
  }
}

List<AppOverflowAction> _projectHomeMenu(
  BuildContext context,
  WidgetRef ref,
  ProjectHomeView view,
) {
  final Project project = view.project;
  final AppOverflowAction? open = projectOpenExternallyMenuItem(
    context,
    ref,
    project,
  );
  return <AppOverflowAction>[
    AppOverflowAction(
      label: Copy.projectAllProjects,
      icon: Icons.folder_open_outlined,
      onTap: () => context.go(_projectsRoot),
    ),
    AppOverflowAction(
      label: Copy.projectNew,
      onTap: () => context.go(_createLocation),
    ),
    AppOverflowAction(
      label: Copy.projectsDuplicate,
      onTap: () => ProjectDuplicateAction.open(
        context,
        sourceId: project.id,
        sourceName: project.name,
      ),
    ),
    AppOverflowAction(
      label: Copy.projectEditTitle,
      icon: Icons.edit_outlined,
      onTap: () => context.go(_edit(project.id)),
    ),
    AppOverflowAction(
      label: Copy.projectSettingsTitle,
      icon: Icons.tune,
      onTap: () => context.go(_settings(project.id)),
    ),
    ?open,
    AppOverflowAction(
      label: project.status == ProjectStatus.archived
          ? Copy.projectUnarchive
          : Copy.projectArchive,
      icon: Icons.inventory_2_outlined,
      onTap: () => unawaited(_archiveThenList(context, ref, project)),
    ),
    AppOverflowAction(
      label: Copy.projectDelete,
      icon: Icons.delete_outline,
      onTap: () => unawaited(_deleteThenList(context, ref, project)),
    ),
  ];
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.cardKey,
    required this.label,
    required this.count,
    required this.semanticLabel,
    required this.onTap,
  });

  final Key cardKey;
  final String label;
  final int count;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(count);
    return AppCard(
      key: cardKey,
      elevationLevel: 0,
      padding: const EdgeInsets.all(Space.x2),
      onTap: onTap,
      child: Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Space.x1),
            Text(
              number,
              style: AppText.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _archiveThenList(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  await ProjectArchiveAction.apply(ref, project);
  if (context.mounted) {
    context.go(_projectsRoot);
  }
}

Future<void> _deleteThenList(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  await ProjectDeleteAction.confirm(context, ref, project);
  if (!context.mounted) {
    return;
  }
  if (ref.read(currentProjectProvider) != project.id) {
    context.go(_projectsRoot);
  }
}

/// Must match [AppRoutes.capture]. This file cannot import `router.dart`.
String _capture(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_captureSegment';
}

/// Must match [AppRoutes.projectEdit].
String _edit(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_editSegment';
}

/// Must match [AppRoutes.projectSettings].
String _settings(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_settingsSegment';
}

String _filtered(String root, String filter) {
  return Uri(
    path: root,
    queryParameters: <String, String>{_filterQuery: filter},
  ).toString();
}

/// Must match [AppRoutes.projectRecords], [AppRoutes.projectQueue] and
/// [AppRoutes.projectExports]. This file cannot import `router.dart`.
String _recordsRoot(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_recordsSegment';
}

String _queueRoot(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_queueSegment';
}

String _exportsRoot(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_exportsSegment';
}

String _reviewList(String id) => _filtered(_recordsRoot(id), _reviewFilter);

String _processList(String id) => _filtered(_queueRoot(id), _processFilter);

String _exportList(String id) => _filtered(_recordsRoot(id), _exportFilter);

String _shareList(String id) => _filtered(_exportsRoot(id), _shareFilter);

const String _projectsRoot = '/projects';
const String _recordsSegment = 'records';
const String _queueSegment = 'queue';
const String _exportsSegment = 'exports';
const String _newSegment = 'new';
const String _editSegment = 'edit';
const String _settingsSegment = 'settings';
const String _captureSegment = 'capture';
const String _createLocation = '$_projectsRoot/$_newSegment';
const String _filterQuery = 'filter';
const String _reviewFilter = 'needsReview';
const String _processFilter = 'queued';
const String _exportFilter = 'approved';
const String _shareFilter = 'share';
