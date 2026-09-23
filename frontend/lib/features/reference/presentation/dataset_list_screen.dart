import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/reference_dataset.dart';
import '../reference.dart' show referenceRepositoryProvider;

/// A project's reference datasets with import as the empty next action.
class DatasetListScreen extends ConsumerWidget {
  /// Creates the list.
  const DatasetListScreen({super.key, this.projectId});

  /// Owning project when opened from a project route.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? id = projectId ?? ref.watch(currentProjectProvider);
    final AsyncValue<List<ReferenceDataset>> value = id == null || id.isEmpty
        ? const AsyncValue<List<ReferenceDataset>>.data(<ReferenceDataset>[])
        : ref.watch(datasetListProvider(id));
    return AppPage(
      key: const ValueKey<String>('route-datasets'),
      title: Copy.navDatasets,
      showAppBar: false,
      inset: false,
      scrollable: false,
      footer: value.hasValue
          ? AppPrimaryAction(
              label: Copy.datasetsImport,
              onPressed: () => context.go(_importLocation(id ?? '')),
            )
          : null,
      body: AsyncValueView<List<ReferenceDataset>>(
        value: value,
        isEmpty: (List<ReferenceDataset> rows) => rows.isEmpty,
        empty: () => AppEmptyState(
          icon: Icons.table_chart_outlined,
          headline: Copy.datasetsEmptyHeadline,
          message: Copy.datasetsEmptyMessage,
          actionLabel: Copy.datasetsImport,
          onAction: () => context.go(_importLocation(id ?? '')),
        ),
        onRetry: id == null
            ? null
            : () => ref.invalidate(datasetListProvider(id)),
        data: (List<ReferenceDataset> rows) {
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              final ReferenceDataset dataset = rows[index];
              return AppListTile(
                title: dataset.name,
                subtitle: Copy.datasetListSubtitle(
                  rows: dataset.rowCount,
                  source: Copy.datasetSourceLabel(dataset.source.name),
                  importedAt: DateFormat.yMMMd().format(
                    dataset.importedAt.toLocal(),
                  ),
                ),
                onTap: () => context.go(_browserLocation(id ?? '', dataset.id)),
              );
            },
          );
        },
      ),
    );
  }
}

/// Live datasets for [projectId].
final datasetListProvider = StreamProvider.autoDispose
    .family<List<ReferenceDataset>, String>((Ref ref, String projectId) {
      return ref.watch(referenceRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);

String _importLocation(String projectId) {
  return RoutePaths.projectDatasetImport(projectId);
}

String _browserLocation(String projectId, String datasetId) {
  return RoutePaths.projectDataset(projectId, datasetId);
}
