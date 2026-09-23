import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';
import '../reference.dart' show referenceRepositoryProvider;

/// Virtualised, paged, searchable browser for one dataset.
class DatasetBrowserScreen extends ConsumerStatefulWidget {
  /// Creates the browser for [datasetId] in [projectId].
  const DatasetBrowserScreen({
    super.key,
    required this.datasetId,
    this.projectId,
    this.failure,
  });

  /// Dataset to browse.
  final String datasetId;

  /// Owning project for navigation.
  final String? projectId;

  /// Injected failure for widget tests.
  final Failure? failure;

  @override
  ConsumerState<DatasetBrowserScreen> createState() =>
      _DatasetBrowserScreenState();
}

class _DatasetBrowserScreenState extends ConsumerState<DatasetBrowserScreen> {
  final List<ReferenceRow> _rows = <ReferenceRow>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Failure? _error;
  String _query = '';
  Set<String> _visible = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure ?? _error;
    if (failure != null) {
      return AppPage(
        title: Copy.navDatasets,
        showAppBar: false,
        body: AsyncValueView<void>(
          value: AsyncValue<void>.error(failure, StackTrace.empty),
          data: (_) => const SizedBox.shrink(),
          onRetry: () => unawaited(_reload()),
        ),
      );
    }
    final AsyncValue<ReferenceDataset?> header = ref.watch(
      datasetHeaderProvider(widget.datasetId),
    );
    return AppPage(
      title: header.asData?.value?.name ?? Copy.navDatasets,
      showAppBar: false,
      inset: false,
      scrollable: false,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchField(
              hint: Copy.datasetsSearchHint,
              text: _query,
              onChanged: (String value) {
                _query = value;
                unawaited(_reload());
              },
            ),
          ),
          if (_narrow(context) && header.asData?.value != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _pickColumns(header.asData!.value!),
                child: const Text(Copy.datasetsColumns),
              ),
            ),
          Expanded(
            child: _loading
                ? AsyncValueView<List<ReferenceRow>>(
                    value: const AsyncValue<List<ReferenceRow>>.loading(),
                    data: (_) => const SizedBox.shrink(),
                  )
                : _rows.isEmpty
                ? const AppEmptyState(
                    icon: Icons.table_rows_outlined,
                    headline: Copy.datasetsBrowserEmptyHeadline,
                    message: Copy.datasetsBrowserEmptyMessage,
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notice) {
                      if (notice.metrics.pixels >
                              notice.metrics.maxScrollExtent - 200 &&
                          !_loadingMore &&
                          _hasMore) {
                        unawaited(_loadMore(header.asData?.value));
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: _rows.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ReferenceRow row = _rows[index];
                        final ReferenceDataset? dataset = header.asData?.value;
                        final List<String> cols = _columnsFor(dataset);
                        return AppListTile(
                          title: row.key,
                          subtitle: <String>[
                            for (final String column in cols)
                              if (column != dataset?.keyColumn)
                                row.values[column] ?? '',
                            if (row.addedOnDevice) Copy.datasetsAddedOnDevice,
                          ].where((String s) => s.isNotEmpty).join(' · '),
                          onTap: () => _openRow(row),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<String> _columnsFor(ReferenceDataset? dataset) {
    if (dataset == null) {
      return const <String>[];
    }
    if (_visible.isNotEmpty) {
      return <String>[
        dataset.keyColumn,
        ...dataset.columns.where(_visible.contains),
      ];
    }
    final List<String> rest = <String>[
      for (final String column in dataset.columns)
        if (column != dataset.keyColumn) column,
    ];
    return <String>[dataset.keyColumn, ...rest.take(2)];
  }

  bool _narrow(BuildContext context) {
    return context.sizeClass == SizeClass.compact;
  }

  Future<void> _pickColumns(ReferenceDataset dataset) async {
    final Set<String> next = Set<String>.of(
      _visible.isEmpty ? dataset.columns.take(3) : _visible,
    );
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(Copy.datasetsColumns),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setLocal) {
              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    for (final String column in dataset.columns)
                      CheckboxListTile(
                        title: Text(column),
                        value: next.contains(column),
                        onChanged: (bool? value) {
                          setLocal(() {
                            if (value ?? false) {
                              next.add(column);
                            } else {
                              next.remove(column);
                            }
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() => _visible = next);
                Navigator.of(context).pop();
              },
              child: const Text(Copy.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _rows.clear();
      _hasMore = true;
    });
    await _loadMore(null, reset: true);
  }

  Future<void> _loadMore(ReferenceDataset? _, {bool reset = false}) async {
    if (_loadingMore) {
      return;
    }
    setState(() => _loadingMore = true);
    final Result<List<ReferenceRow>> page = await ref
        .read(referenceRepositoryProvider)
        .pageRows(
          datasetId: widget.datasetId,
          offset: reset ? 0 : _rows.length,
          limit: 50,
          query: _query,
        );
    if (!mounted) {
      return;
    }
    switch (page) {
      case FailureResult<List<ReferenceRow>>(:final Failure failure):
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = failure;
        });
      case Success<List<ReferenceRow>>(:final List<ReferenceRow> value):
        setState(() {
          if (reset) {
            _rows
              ..clear()
              ..addAll(value);
          } else {
            _rows.addAll(value);
          }
          _hasMore = value.length >= 50;
          _loading = false;
          _loadingMore = false;
        });
    }
  }

  void _openRow(ReferenceRow row) {
    final String? projectId =
        widget.projectId ?? ref.read(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      return;
    }
    context.go(
      RoutePaths.projectDatasetRow(projectId, widget.datasetId, row.id),
    );
  }
}

/// Dataset header for the browser title.
final datasetHeaderProvider = FutureProvider.autoDispose
    .family<ReferenceDataset?, String>((Ref ref, String id) async {
      final Result<ReferenceDataset?> result = await ref
          .watch(referenceRepositoryProvider)
          .byId(id);
      return switch (result) {
        Success<ReferenceDataset?>(:final ReferenceDataset? value) => value,
        FailureResult<ReferenceDataset?>() => null,
      };
    }, retry: (int _, Object _) => null);
