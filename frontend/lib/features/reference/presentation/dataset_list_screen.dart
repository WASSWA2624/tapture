import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/reference_dataset.dart';
import '../reference.dart' show referenceRepositoryProvider;

/// A project's reference datasets: each with its row count, source and
/// import date, and import as the way to add one (task 010 step 4).
class DatasetListScreen extends ConsumerWidget {
  /// Creates the list for [projectId], or for the open project when null.
  const DatasetListScreen({super.key, this.projectId});

  /// Owning project when opened from a project route.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? id =
        _present(projectId) ?? _present(ref.watch(currentProjectProvider));
    if (id == null) {
      return AppPage(
        key: const ValueKey<String>('route-datasets'),
        title: localCopy.navDatasets,
        body: AppEmptyState(
          icon: AppIcons.dataset,
          headline: localCopy.datasetsNoProjectHeadline,
          message: localCopy.datasetsNoProjectMessage,
          actionLabel: localCopy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
      );
    }
    final AsyncValue<List<ReferenceDataset>> value = ref.watch(
      datasetListProvider(id),
    );
    void import() => context.push(RoutePaths.projectDatasetImport(id));
    return AppPage(
      key: const ValueKey<String>('route-datasets'),
      title: localCopy.navDatasets,
      inset: false,
      scrollable: false,
      // The empty list offers import itself, so the footer only appears
      // beside rows and the action is never shown twice.
      footer: (value.asData?.value.isNotEmpty ?? false)
          ? AppPrimaryAction(label: localCopy.datasetsImport, onPressed: import)
          : null,
      body: AsyncValueView<List<ReferenceDataset>>(
        value: value,
        isEmpty: (List<ReferenceDataset> rows) => rows.isEmpty,
        empty: () => SingleChildScrollView(
          child: AppEmptyState(
            icon: AppIcons.dataset,
            headline: Copy.of(context).datasetsEmptyHeadline,
            message: Copy.of(context).datasetsEmptyMessage,
            actionLabel: Copy.of(context).datasetsImport,
            onAction: import,
          ),
        ),
        onRetry: () => ref.invalidate(datasetListProvider(id)),
        data: (List<ReferenceDataset> rows) {
          return ListView.builder(
            key: const ValueKey<String>('dataset-list'),
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              final LocalizedCopy localCopy = Copy.of(context);

              final ReferenceDataset dataset = rows[index];
              return AppListTile(
                key: ValueKey<String>('dataset-${dataset.id}'),
                title: dataset.name,
                subtitle: localCopy.datasetListSubtitle(
                  rows: dataset.rowCount,
                  source: localCopy.datasetSourceLabel(dataset.source.name),
                  importedAt: dataset.importedAt,
                ),
                trailing: const Icon(AppIcons.open),
                onTap: () =>
                    context.push(RoutePaths.projectDataset(id, dataset.id)),
              );
            },
          );
        },
      ),
    );
  }
}

/// Live datasets for [projectId]: its own and the global ones.
final datasetListProvider = StreamProvider.autoDispose
    .family<List<ReferenceDataset>, String>((Ref ref, String projectId) {
      return ref.watch(referenceRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);

String? _present(String? id) => id == null || id.isEmpty ? null : id;
