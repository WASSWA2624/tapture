import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/merge/merge.dart' show startPackageImport;
import 'package:tapture/features/templates/templates.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'captured_records.dart';
import 'current_project.dart';
import 'project_archive_action.dart';
import 'project_delete_action.dart';
import 'project_duplicate_action.dart';
import 'project_open_externally_action.dart';
import 'project_record_filter.dart';

part 'project_home_menu.dart';

/// Open-project home: template setup when empty, with capture always available.
class ProjectHomeScreen extends ConsumerWidget {
  /// Creates the open-project home.
  const ProjectHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Project? details = ref.watch(currentProjectDetailsProvider);
    final AsyncValue<Project?> value = ref.watch(projectHomeProvider);
    final Project? project = value.asData?.value;
    final int records =
        ref.watch(projectHomeRecordCountProvider).asData?.value ?? 0;
    final String? openId = details?.id;
    final AsyncValue<List<TemplateDef>> homeTemplates = ref.watch(
      projectHomeTemplatesProvider(openId ?? ''),
    );
    final bool needsTemplate = homeTemplates.asData?.value.isEmpty ?? false;
    return AppPage(
      key: const ValueKey<String>('route-project'),
      title: details?.name ?? localCopy.navProjects,
      showAppBar: false,
      overflow: project == null
          ? const <AppOverflowAction>[]
          : _projectHomeMenu(context, ref, project),
      scrollable: false,
      footer: project == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppPrimaryAction(
                  label: needsTemplate
                      ? localCopy.projectAddTemplate
                      : records == 0
                      ? localCopy.captureStart
                      : localCopy.captureMore,
                  onPressed: () => context.go(
                    needsTemplate
                        ? _templates(project.id)
                        : _capture(project.id),
                  ),
                ),
                if (needsTemplate) ...<Widget>[
                  const SizedBox(height: Space.x1),
                  AppButton(
                    label: localCopy.projectCaptureNow,
                    variant: AppButtonVariant.text,
                    onPressed: () => context.go(_capture(project.id)),
                  ),
                ],
              ],
            ),
      body: AsyncValueView<Project?>(
        value: value,
        isEmpty: (Project? loaded) => loaded == null,
        empty: () => AppEmptyState(
          icon: AppIcons.project,
          headline: Copy.of(context).homeEmptyHeadline,
          message: Copy.of(context).homeEmptyMessage,
          actionLabel: Copy.of(context).navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
        onRetry: () => ref.invalidate(projectListProvider),
        data: (Project? loaded) => _HomeBody(project: loaded!),
      ),
    );
  }
}

/// Templates of [projectId], so adding one updates the footer immediately.
final projectHomeTemplatesProvider =
    StreamProvider.family<List<TemplateDef>, String>((
      Ref ref,
      String projectId,
    ) {
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);

/// How many records the open project already holds: the live ones its home
/// lists. Derived (FE-STATE-06).
final StreamProvider<int> projectHomeRecordCountProvider = StreamProvider<int>((
  Ref ref,
) {
  final String? id = ref.watch(currentProjectProvider);
  if (id == null) {
    return Stream<int>.value(0);
  }
  return ref
      .watch(projectRepositoryProvider)
      .watchRecords(id, statuses: capturedItemStatuses)
      .map((List<ProjectRecordRow> rows) => rows.length);
}, retry: (int _, Object _) => null);

/// The open project once the list has loaded. Null when none is open;
/// loading and failure follow the list (FE-STATE-06).
final Provider<AsyncValue<Project?>> projectHomeProvider =
    Provider<AsyncValue<Project?>>((Ref ref) {
      final Project? details = ref.watch(currentProjectDetailsProvider);
      final AsyncValue<List<ProjectListRow>> list = ref.watch(
        projectListProvider,
      );
      return list.when(
        data: (List<ProjectListRow> _) => AsyncData<Project?>(details),
        error: AsyncError<Project?>.new,
        loading: () => const AsyncLoading<Project?>(),
      );
    });

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool shellOwns = ShellHeaderScope.ownsHeaderOf(context);
    final double gutter = AppPage.gutter(context);
    final String query = ref.watch(capturedItemsQueryProvider);
    final int activeFilters = ref.watch(projectRecordFilterProvider).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!shellOwns)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Text(project.name, style: AppText.title)),
                AppOverflowMenu(items: _projectHomeMenu(context, ref, project)),
              ],
            ),
          ),
        // Pinned at the very top so a long home scrolls under it.
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x1, gutter, Space.x2),
          child: AppSearchField(
            key: const ValueKey<String>('home-search'),
            hint: localCopy.projectRecordsSearchHint,
            text: query,
            onChanged: (String text) {
              ref.read(capturedItemsQueryProvider.notifier).set(text);
            },
            onFilter: () => unawaited(
              showProjectRecordFilters(
                context,
                ref,
                ref.read(capturedItemsProvider(project.id)).asData?.value ??
                    const <ProjectRecordRow>[],
              ),
            ),
            activeFilterCount: activeFilters,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: CapturedRecords(projectId: project.id),
          ),
        ),
      ],
    );
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

/// Must match [AppRoutes.projectSettings].
String _settings(String id) {
  return RoutePaths.projectSettings(id);
}
