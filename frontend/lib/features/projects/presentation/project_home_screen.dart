import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'captured_items.dart';
import 'current_project.dart';
import 'project_archive_action.dart';
import 'project_delete_action.dart';
import 'project_duplicate_action.dart';
import 'project_open_externally_action.dart';
import 'project_template_selection.dart';

/// Open-project home: what to do next, with one primary capture action.
class ProjectHomeScreen extends ConsumerWidget {
  /// Creates the open-project home.
  const ProjectHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? details = ref.watch(currentProjectDetailsProvider);
    final AsyncValue<ProjectHomeView?> value = ref.watch(projectHomeProvider);
    final ProjectHomeView? view = value.asData?.value;
    final int records =
        ref.watch(projectHomeRecordCountProvider).asData?.value ?? 0;
    final String? openId = details?.id;
    final AsyncValue<List<TemplateDef>> homeTemplates = ref.watch(
      projectHomeTemplatesProvider(openId ?? ''),
    );
    final bool canCapture = homeTemplates.maybeWhen(
      data: (List<TemplateDef> loaded) => loaded.isNotEmpty,
      orElse: () => false,
    );
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
              label: records == 0 ? Copy.captureStart : Copy.captureMore,
              caption: homeTemplates.hasValue && !canCapture
                  ? Copy.captureNeedsTemplate
                  : null,
              onPressed: canCapture
                  ? () => context.go(_capture(view.project.id))
                  : null,
            ),
      body: AsyncValueView<ProjectHomeView?>(
        value: value,
        isEmpty: (ProjectHomeView? loaded) => loaded == null,
        empty: () => AppEmptyState(
          icon: AppIcons.project,
          headline: Copy.homeEmptyHeadline,
          message: Copy.homeEmptyMessage,
          actionLabel: Copy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
        onRetry: () {
          ref.invalidate(projectListProvider);
          ref.invalidate(projectHomeCountsProvider);
          ref.invalidate(projectHomeAssociationsProvider);
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

/// Live project-owned context and template associations.
typedef ProjectHomeAssociations = ({int contextLevels, int templates});

final projectHomeTemplatesProvider =
    StreamProvider.family<List<TemplateDef>, String>((
      Ref ref,
      String projectId,
    ) {
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);

/// Combines association totals without storing duplicate counters.
final Provider<AsyncValue<ProjectHomeAssociations>>
projectHomeAssociationsProvider = Provider<AsyncValue<ProjectHomeAssociations>>(
  (Ref ref) {
    final String? projectId = ref.watch(currentProjectProvider);
    if (projectId == null) {
      return const AsyncData<ProjectHomeAssociations>((
        contextLevels: 0,
        templates: 0,
      ));
    }
    final AsyncValue<ContextState> context = ref.watch(
      projectContextProvider(projectId),
    );
    final AsyncValue<List<TemplateDef>> templates = ref.watch(
      projectHomeTemplatesProvider(projectId),
    );
    return context.when(
      data: (ContextState loadedContext) {
        return templates.when(
          data: (List<TemplateDef> loadedTemplates) {
            return AsyncData<ProjectHomeAssociations>((
              contextLevels: loadedContext.levels.length,
              templates: loadedTemplates.length,
            ));
          },
          error: AsyncError<ProjectHomeAssociations>.new,
          loading: () => const AsyncLoading<ProjectHomeAssociations>(),
        );
      },
      error: AsyncError<ProjectHomeAssociations>.new,
      loading: () => const AsyncLoading<ProjectHomeAssociations>(),
    );
  },
);

/// Pinned context label on the home header from the open project context.
final Provider<String> projectHomeContextProvider = Provider<String>((Ref ref) {
  final AsyncValue<ContextState> value = ref.watch(openProjectContextProvider);
  return contextStatusLabel(value.asData?.value ?? const ContextState());
});

const List<String> _homeRecordStatuses = <String>[
  'draft',
  'captured',
  'CAPTURED',
  'queued',
  'processing',
  'needsReview',
  'approved',
];

/// How many records the open project already holds. Derived (FE-STATE-06).
final StreamProvider<int> projectHomeRecordCountProvider = StreamProvider<int>((
  Ref ref,
) {
  final String? id = ref.watch(currentProjectProvider);
  if (id == null) {
    return Stream<int>.value(0);
  }
  return ref
      .watch(projectRepositoryProvider)
      .watchRecords(id, statuses: _homeRecordStatuses)
      .map((List<ProjectRecordRow> rows) => rows.length);
}, retry: (int _, Object _) => null);

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
    final AsyncValue<ProjectHomeAssociations> associations = ref.watch(
      projectHomeAssociationsProvider,
    );
    final bool shellOwns = ShellHeaderScope.ownsHeaderOf(context);
    final double gutter = AppPage.gutter(context);
    final String query = ref.watch(capturedItemsQueryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!shellOwns)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Text(view.project.name, style: AppText.title)),
                AppOverflowMenu(items: _projectHomeMenu(context, ref, view)),
              ],
            ),
          ),
        // Pinned at the very top so a long home scrolls under it.
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x1, gutter, Space.x2),
          child: AppSearchField(
            key: const ValueKey<String>('home-search'),
            hint: Copy.search,
            text: query,
            onChanged: (String text) {
              ref.read(capturedItemsQueryProvider.notifier).set(text);
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(view.context, style: AppText.caption),
                      const SizedBox(height: Space.x3),
                      ..._templateSwitch(ref, view.project.id),
                      if (associations.hasError) ...<Widget>[
                        const SizedBox(height: Space.x2),
                        const Text(Copy.projectAssociationCountUnavailable),
                        AppButton(
                          label: Copy.projectAssociationRetry,
                          variant: AppButtonVariant.text,
                          onPressed: () {
                            ref.invalidate(
                              projectContextProvider(view.project.id),
                            );
                            ref.invalidate(
                              projectHomeTemplatesProvider(view.project.id),
                            );
                            ref.invalidate(projectHomeAssociationsProvider);
                          },
                        ),
                      ],
                      const SizedBox(height: Space.x4),
                      ..._countRows(context, counts),
                    ],
                  ),
                ),
                const SizedBox(height: Space.x4),
                CapturedItems(projectId: view.project.id),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _countRows(BuildContext context, ProjectHomeCounts counts) {
    final String projectId = view.project.id;
    final List<Widget> cards = <Widget>[
      _CountCard(
        cardKey: const ValueKey<String>('home-review'),
        label: Copy.homeReview,
        message: Copy.homeReviewPending(counts.review),
        icon: AppIcons.review,
        semanticLabel: Copy.homeReviewPending(counts.review),
        onTap: () => unawaited(context.push(_reviewList(projectId))),
      ),
      _CountCard(
        cardKey: const ValueKey<String>('home-process'),
        label: Copy.homeProcess,
        message: Copy.homeProcessPending(counts.process),
        icon: AppIcons.queued,
        semanticLabel: Copy.homeProcessPending(counts.process),
        onTap: () => unawaited(context.push(_processList(projectId))),
      ),
      _CountCard(
        cardKey: const ValueKey<String>('home-export'),
        label: Copy.homeExport,
        message: Copy.homeExportPending(counts.toExport),
        icon: AppIcons.export,
        semanticLabel: Copy.homeExportPending(counts.toExport),
        onTap: () => unawaited(context.push(_exportList(projectId))),
      ),
      _CountCard(
        cardKey: const ValueKey<String>('home-share'),
        label: Copy.homeShare,
        message: Copy.homeSharePending(counts.toShare),
        icon: AppIcons.share,
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

List<Widget> _templateSwitch(WidgetRef ref, String projectId) {
  final AsyncValue<List<TemplateDef>> templates = ref.watch(
    projectHomeTemplatesProvider(projectId),
  );
  return templates.maybeWhen(
    data: (List<TemplateDef> loaded) {
      if (loaded.isEmpty) {
        return const <Widget>[
          Text(Copy.contextNoTemplatesHeadline, style: AppText.body),
        ];
      }
      final String chosen = ref.watch(projectTemplateSelectionProvider);
      final String value = chosen.isEmpty ? loaded.first.id : chosen;
      return <Widget>[
        AppRadioGroup<String>(
          label: Copy.navTemplates,
          framed: false,
          value: value,
          options: <Choice<String>>[
            for (final TemplateDef template in loaded)
              Choice<String>(template.id, template.name),
          ],
          onChanged: (String id) {
            ref.read(projectTemplateSelectionProvider.notifier).select(id);
          },
        ),
      ];
    },
    orElse: () => const <Widget>[],
  );
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
      label: Copy.navTemplates,
      icon: AppIcons.template,
      onTap: () => context.push(_templates(project.id)),
    ),
    AppOverflowAction(
      label: Copy.contextPinnedTitle,
      icon: AppIcons.pin,
      onTap: () => unawaited(
        showPinnedFieldsSheet(context: context, projectId: project.id),
      ),
    ),
    AppOverflowAction(
      label: Copy.contextHierarchyTitle,
      icon: AppIcons.context,
      onTap: () => unawaited(context.push(_context(project.id))),
    ),
    AppOverflowAction(
      label: Copy.projectExport,
      icon: AppIcons.export,
      onTap: () => context.push(RoutePaths.projectExports(project.id)),
    ),
    AppOverflowAction(
      label: Copy.projectsDuplicate,
      icon: AppIcons.duplicate,
      onTap: () => ProjectDuplicateAction.open(
        context,
        sourceId: project.id,
        sourceName: project.name,
      ),
    ),
    AppOverflowAction(
      label: Copy.projectEditTitle,
      icon: AppIcons.edit,
      onTap: () => context.go(_edit(project.id)),
    ),
    AppOverflowAction(
      label: Copy.projectSettingsTitle,
      icon: AppIcons.settings,
      onTap: () => context.go(_settings(project.id)),
    ),
    ?open,
    AppOverflowAction(
      label: project.status == ProjectStatus.archived
          ? Copy.projectUnarchive
          : Copy.projectArchive,
      icon: project.status == ProjectStatus.archived
          ? AppIcons.unarchive
          : AppIcons.archive,
      onTap: () => unawaited(_archiveThenList(context, ref, project)),
    ),
    AppOverflowAction(
      label: Copy.projectDeleteMenu,
      icon: AppIcons.delete,
      onTap: () => unawaited(_deleteThenList(context, ref, project)),
    ),
  ];
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.cardKey,
    required this.label,
    required this.message,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final Key cardKey;
  final String label;
  final String message;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: cardKey,
      padding: const EdgeInsets.all(Space.x3),
      onTap: onTap,
      child: Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: Space.x5, color: context.colors.onSurface),
                const SizedBox(width: Space.x1),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              message,
              style: AppText.caption,
              maxLines: 3,
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
    context.go(RoutePaths.projects);
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
    context.go(RoutePaths.projects);
  }
}

/// Must match [AppRoutes.capture]. This file cannot import `router.dart`.
String _capture(String id) {
  return RoutePaths.projectCapture(id);
}

/// Must match the project context route. This file cannot import `router.dart`.
String _context(String id) {
  return RoutePaths.projectContext(id);
}

/// Must match [AppRoutes.projectTemplates].
String _templates(String id) {
  return RoutePaths.projectTemplates(id);
}

/// Must match [AppRoutes.projectEdit].
String _edit(String id) {
  return RoutePaths.projectEdit(id);
}

/// Must match [AppRoutes.projectSettings].
String _settings(String id) {
  return RoutePaths.projectSettings(id);
}

String _filtered(String root, String filter) {
  return Uri(
    path: root,
    queryParameters: <String, String>{RoutePaths.filterQuery: filter},
  ).toString();
}

/// Must match [AppRoutes.projectRecords], [AppRoutes.projectQueue] and
/// [AppRoutes.projectExports]. This file cannot import `router.dart`.
String _recordsRoot(String id) {
  return RoutePaths.projectRecords(id);
}

String _queueRoot(String id) {
  return RoutePaths.projectQueue(id);
}

String _exportsRoot(String id) {
  return RoutePaths.projectExports(id);
}

String _reviewList(String id) => _filtered(_recordsRoot(id), _reviewFilter);

String _processList(String id) => _filtered(_queueRoot(id), _processFilter);

String _exportList(String id) => _filtered(_recordsRoot(id), _exportFilter);

String _shareList(String id) => _filtered(_exportsRoot(id), _shareFilter);

const String _reviewFilter = 'needsReview';
const String _processFilter = 'queued';
const String _exportFilter = 'approved';
const String _shareFilter = 'share';
