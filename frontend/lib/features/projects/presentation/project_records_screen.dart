import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'captured_items.dart';

/// Records for the open project, limited by the route filter.
final class ProjectRecordsScreen extends ConsumerWidget {
  /// Creates the list for [projectId].
  const ProjectRecordsScreen({required this.projectId, super.key});

  /// Project whose records are shown.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String filter =
        GoRouterState.of(context).uri.queryParameters[RoutePaths.filterQuery] ??
        '';
    final List<String> statuses = _statusesFor(filter);
    final AsyncValue<List<ProjectRecordRow>> value = ref.watch(
      _projectRecordsProvider((projectId: projectId, statuses: statuses)),
    );
    return AppPage(
      key: const ValueKey<String>('route-records'),
      title: Copy.navRecords,
      body: AsyncValueView<List<ProjectRecordRow>>(
        value: value,
        onRetry: () => ref.invalidate(
          _projectRecordsProvider((projectId: projectId, statuses: statuses)),
        ),
        isEmpty: (List<ProjectRecordRow> rows) => rows.isEmpty,
        empty: () => const AppEmptyState(
          icon: AppIcons.records,
          headline: Copy.projectRecordsEmptyHeadline,
          message: Copy.projectRecordsEmptyMessage,
        ),
        data: (List<ProjectRecordRow> rows) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              final ProjectRecordRow row = rows[index];
              return CapturedItemTile(
                projectId: projectId,
                row: row,
                position: index + 1,
              );
            },
          );
        },
      ),
    );
  }
}

typedef _RecordQuery = ({String projectId, List<String> statuses});

final _projectRecordsProvider =
    StreamProvider.family<List<ProjectRecordRow>, _RecordQuery>((
      Ref ref,
      _RecordQuery query,
    ) {
      return ref
          .watch(projectRepositoryProvider)
          .watchRecords(query.projectId, statuses: query.statuses);
    }, retry: (int _, Object _) => null);

List<String> _statusesFor(String filter) {
  return switch (filter) {
    'needsReview' => const <String>['needsReview'],
    'approved' => const <String>['approved'],
    _ => const <String>[
      'draft',
      'captured',
      'CAPTURED',
      'queued',
      'processing',
    ],
  };
}
