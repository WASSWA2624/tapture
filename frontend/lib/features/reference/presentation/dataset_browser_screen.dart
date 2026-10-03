import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';
import 'dataset_browser_controller.dart';
import 'dataset_browser_providers.dart';

/// A virtualised, paged, searchable browser for one dataset (task 010
/// step 4). Only the pages on screen are read, so ten thousand rows scroll
/// like ten, and an edited row shows its new values on return.
class DatasetBrowserScreen extends ConsumerWidget {
  /// Creates the browser for [datasetId] in [projectId].
  const DatasetBrowserScreen({
    super.key,
    required this.datasetId,
    this.projectId,
  });

  /// Dataset to browse.
  final String datasetId;

  /// Owning project for navigation; the dataset's or the open one when null.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<ReferenceDataset?> header = ref.watch(
      datasetHeaderProvider(datasetId),
    );
    final ReferenceDataset? dataset = header.asData?.value;
    final String? project =
        _present(projectId) ??
        _present(dataset?.projectId) ??
        _present(ref.watch(currentProjectProvider));
    return AppPage(
      key: const ValueKey<String>('route-dataset'),
      title: dataset?.name ?? localCopy.navDatasets,
      inset: false,
      scrollable: false,
      overflow: dataset == null
          ? const <AppOverflowAction>[]
          : <AppOverflowAction>[
              AppOverflowAction(
                key: const ValueKey<String>('dataset-columns'),
                label: localCopy.datasetsColumns,
                icon: AppIcons.columns,
                onTap: () => unawaited(_pickColumns(context, dataset)),
              ),
              AppOverflowAction(
                key: const ValueKey<String>('dataset-export-csv'),
                label: localCopy.datasetsExportCsv,
                icon: AppIcons.export,
                onTap: () => unawaited(_export(context, ref, dataset, false)),
              ),
              AppOverflowAction(
                key: const ValueKey<String>('dataset-export-json'),
                label: localCopy.datasetsExportJson,
                icon: AppIcons.export,
                onTap: () => unawaited(_export(context, ref, dataset, true)),
              ),
            ],
      body: AsyncValueView<ReferenceDataset?>(
        value: header,
        isEmpty: (ReferenceDataset? found) => found == null,
        empty: () => SingleChildScrollView(
          child: AppEmptyState(
            icon: AppIcons.dataset,
            headline: Copy.of(context).datasetsMissingHeadline,
            message: Copy.of(context).datasetsMissingMessage,
            actionLabel: Copy.of(context).navDatasets,
            onAction: () => context.go(
              project == null
                  ? RoutePaths.projects
                  : RoutePaths.projectDatasets(project),
            ),
          ),
        ),
        onRetry: () => ref.invalidate(datasetHeaderProvider(datasetId)),
        data: (ReferenceDataset? found) =>
            _DatasetRows(dataset: found!, projectId: project),
      ),
    );
  }

  Future<void> _pickColumns(BuildContext context, ReferenceDataset dataset) {
    final LocalizedCopy localCopy = Copy.of(context);

    return showAppSheet<void>(
      context,
      title: localCopy.datasetsColumns,
      contentSized: true,
      builder: (BuildContext _) => _ColumnPicker(dataset: dataset),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ReferenceDataset dataset,
    bool json,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<String?>? saved = await ref
        .read(datasetBrowserControllerProvider(datasetId).notifier)
        .export(dataset, json: json, projectId: projectId);
    if (saved == null || !context.mounted) {
      return;
    }
    switch (saved) {
      case Success<String?>():
        showAppSnack(
          context,
          localCopy.projectExportSaved(dataset.name),
          tone: SnackTone.success,
        );
      case FailureResult<String?>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
    }
  }
}

/// The search field over the rows it filters.
class _DatasetRows extends ConsumerWidget {
  const _DatasetRows({required this.dataset, required this.projectId});

  final ReferenceDataset dataset;
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final DatasetBrowserView view = ref.watch(
      datasetBrowserControllerProvider(dataset.id),
    );
    final DatasetBrowserController controller = ref.read(
      datasetBrowserControllerProvider(dataset.id).notifier,
    );
    final ({String datasetId, String query}) search = (
      datasetId: dataset.id,
      query: view.query,
    );
    final AsyncValue<int> count = ref.watch(datasetRowCountProvider(search));
    final double gutter = AppPage.gutter(context);
    final List<String> shown = _shownColumns(
      dataset,
      view.columns,
      context.responsive(compact: 2, medium: 4, expanded: 6),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x2),
          child: AppSearchField(
            key: const ValueKey<String>('dataset-search'),
            hint: localCopy.datasetsSearchHint,
            text: view.query,
            onChanged: controller.search,
            resultCount: view.query.isEmpty ? null : count.asData?.value,
          ),
        ),
        if (view.exporting)
          AppBanner(
            message: localCopy.datasetsExporting,
            icon: AppIcons.export,
            tone: SnackTone.info,
          ),
        Expanded(
          child: AsyncValueView<int>(
            value: count,
            onRetry: () => ref.invalidate(datasetRowCountProvider(search)),
            isEmpty: (int total) => total == 0,
            empty: () => SingleChildScrollView(
              child: view.query.isEmpty
                  ? AppEmptyState(
                      icon: AppIcons.datasetRow,
                      headline: Copy.of(context).datasetsBrowserEmptyHeadline,
                      message: Copy.of(context).datasetsBrowserEmptyMessage,
                      actionLabel: Copy.of(context).datasetsImport,
                      onAction: projectId == null
                          ? null
                          : () => context.push(
                              RoutePaths.projectDatasetImport(projectId!),
                            ),
                    )
                  : AppEmptyState(
                      icon: AppIcons.searchEmpty,
                      headline: Copy.of(context).datasetsNoMatchHeadline,
                      message: Copy.of(context).datasetsNoMatchMessage,
                      actionLabel: Copy.of(context).datasetsClearSearch,
                      onAction: () => controller.search(''),
                    ),
            ),
            data: (int total) => Scrollbar(
              child: ListView.builder(
                key: const ValueKey<String>('dataset-rows'),
                itemCount: total,
                prototypeItem: const _PrototypeRow(),
                itemBuilder: (BuildContext context, int index) {
                  return _DatasetRow(
                    dataset: dataset,
                    query: view.query,
                    index: index,
                    shown: shown,
                    projectId: projectId,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Row [index] of the browser, read from the page it falls in: the row, a
/// skeleton while its page loads, or why the page failed with a tap to read
/// it again.
class _DatasetRow extends ConsumerWidget {
  const _DatasetRow({
    required this.dataset,
    required this.query,
    required this.index,
    required this.shown,
    required this.projectId,
  });

  final ReferenceDataset dataset;
  final String query;
  final int index;
  final List<String> shown;
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final int size = AppConstants.lists.pageSize;
    final ({String datasetId, String query, int page}) at = (
      datasetId: dataset.id,
      query: query,
      page: index ~/ size,
    );
    final AsyncValue<List<ReferenceRow>> page = ref.watch(
      datasetRowsPageProvider(at),
    );
    final int offset = index % size;
    // A page being read again keeps showing what it held.
    final List<ReferenceRow>? rows = page.value;
    if (rows != null && offset < rows.length) {
      final ReferenceRow row = rows[offset];
      final String? project = projectId;
      return AppListTile(
        key: ValueKey<String>('dataset-row-${row.id}'),
        title: row.key,
        subtitle: localCopy.datasetRowSubtitle(<String>[
          for (final String column in shown) row.values[column] ?? '',
        ], addedOnDevice: row.addedOnDevice),
        trailing: project == null ? null : const Icon(AppIcons.open),
        onTap: project == null
            ? null
            : () => context.push(
                RoutePaths.projectDatasetRow(project, dataset.id, row.id),
              ),
      );
    }
    final Object? error = page.error;
    if (error != null) {
      final Failure failure = Failure.from(error);
      return AppListTile(
        title: Copy.of(context).failureMessage(failure),
        subtitle:
            Copy.of(context).failureRecovery(failure) ?? localCopy.tryAgain,
        leading: Icon(
          AppIcons.error,
          color: context.colors.danger,
          size: Space.x6,
        ),
        onTap: () => ref.invalidate(datasetRowsPageProvider(at)),
      );
    }
    return const AppSkeleton(count: 1);
  }
}

/// What every row measures against, so the list jumps to any of thousands
/// of rows without building the ones between. Laid out once, never shown.
class _PrototypeRow extends StatelessWidget {
  const _PrototypeRow();

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppListTile(
      title: localCopy.datasetsKeyTitle,
      subtitle: localCopy.datasetsAddedOnDevice,
      trailing: const Icon(AppIcons.open),
    );
  }
}

/// The columns shown beside the key, chosen live in a sheet.
class _ColumnPicker extends ConsumerWidget {
  const _ColumnPicker({required this.dataset});

  final ReferenceDataset dataset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final DatasetBrowserView view = ref.watch(
      datasetBrowserControllerProvider(dataset.id),
    );
    final List<String> shown = _shownColumns(
      dataset,
      view.columns,
      context.responsive(compact: 2, medium: 4, expanded: 6),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: AppCheckboxGroup<String>(
        label: localCopy.datasetsVisibleColumns,
        options: <Choice<String>>[
          for (final String column in dataset.columns)
            if (column != dataset.keyColumn) Choice<String>(column, column),
        ],
        value: shown.toSet(),
        onChanged: ref
            .read(datasetBrowserControllerProvider(dataset.id).notifier)
            .showColumns,
      ),
    );
  }
}

/// The columns shown beside the key: the ones chosen, else the first
/// [fallback] after the key (task 010 step 4), in dataset order.
List<String> _shownColumns(
  ReferenceDataset dataset,
  Set<String>? chosen,
  int fallback,
) {
  final List<String> rest = <String>[
    for (final String column in dataset.columns)
      if (column != dataset.keyColumn) column,
  ];
  if (chosen == null) {
    return rest.take(fallback).toList(growable: false);
  }
  return rest.where(chosen.contains).toList(growable: false);
}

String? _present(String? id) => id == null || id.isEmpty ? null : id;
