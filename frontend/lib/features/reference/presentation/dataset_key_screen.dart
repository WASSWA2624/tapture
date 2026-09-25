import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../reference.dart';

/// Ends every import: pick the key column and confirm duplicates.
class DatasetKeyScreen extends ConsumerStatefulWidget {
  /// Creates the key-column screen for [draft].
  const DatasetKeyScreen({super.key, this.draft, this.failure});

  /// Parsed import ready to save. Null shows the empty state.
  final DatasetImportDraft? draft;

  /// Injected failure for widget tests.
  final Failure? failure;

  @override
  ConsumerState<DatasetKeyScreen> createState() => _DatasetKeyScreenState();
}

class _DatasetKeyScreenState extends ConsumerState<DatasetKeyScreen> {
  String? _keyColumn;
  bool _allowDuplicates = false;
  bool _saving = false;
  Failure? _saveFailure;

  @override
  void initState() {
    super.initState();
    _keyColumn = widget.draft?.dataset.keyColumn;
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure ?? _saveFailure;
    if (failure != null) {
      return AppPage(
        title: Copy.datasetsKeyTitle,
        showAppBar: false,
        body: AsyncValueView<void>(
          value: AsyncValue<void>.error(failure, StackTrace.empty),
          data: (_) => const SizedBox.shrink(),
          onRetry: () => setState(() => _saveFailure = null),
        ),
      );
    }
    final DatasetImportDraft? draft = widget.draft;
    if (draft == null) {
      return const AppPage(
        title: Copy.datasetsKeyTitle,
        showAppBar: false,
        body: AppEmptyState(
          icon: AppIcons.dataset,
          headline: Copy.datasetsEmptyHeadline,
          message: Copy.datasetsEmptyMessage,
        ),
      );
    }
    final String key = _keyColumn ?? draft.dataset.keyColumn;
    final int dups = draft.duplicateCounts[key] ?? 0;
    final List<String> samples = draft.samples[key] ?? const <String>[];
    return AppPage(
      title: Copy.datasetsKeyTitle,
      showAppBar: false,
      scrollable: false,
      footer: AppPrimaryAction(
        label: dups > 0 && !_allowDuplicates
            ? Copy.datasetsAllowDuplicates
            : Copy.datasetsSaveImport,
        onPressed: _saving
            ? null
            : () => unawaited(_save(draft, key, allowDuplicates: dups > 0)),
      ),
      body: ListView(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(Space.x4),
            child: Text(Copy.datasetsKeyMessage),
          ),
          for (final String column in draft.dataset.columns)
            AppListTile(
              title: column,
              subtitle:
                  '${Copy.datasetsDuplicateCount(draft.duplicateCounts[column] ?? 0)}'
                  '${(draft.samples[column] ?? const <String>[]).isEmpty ? '' : ' · ${(draft.samples[column] ?? const <String>[]).take(2).join(', ')}'}',
              selected: column == key,
              onTap: () => setState(() {
                _keyColumn = column;
                _allowDuplicates = false;
              }),
            ),
          if (dups > 0) ...<Widget>[
            Padding(
              padding: const EdgeInsets.all(Space.x4),
              child: Text(
                '${Copy.datasetsDuplicateCount(dups)}. '
                '${Copy.datasetsCollidingValues(samples.where((String s) => s.isNotEmpty).take(3).toList())}',
              ),
            ),
            AppButton(
              label: Copy.datasetsAllowDuplicates,
              onPressed: () => setState(() => _allowDuplicates = true),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(
    DatasetImportDraft draft,
    String key, {
    required bool allowDuplicates,
  }) async {
    final int dups = draft.duplicateCounts[key] ?? 0;
    if (dups > 0 && !allowDuplicates && !_allowDuplicates) {
      setState(() => _allowDuplicates = true);
      return;
    }
    setState(() => _saving = true);
    final List<ReferenceRow> rows = <ReferenceRow>[
      for (final ReferenceRow row in draft.rows)
        row.copyWith(key: row.values[key] ?? row.key),
    ];
    final ReferenceDataset dataset = draft.dataset.copyWith(
      keyColumn: key,
      duplicatesAllowed: dups > 0,
      rowCount: rows.length,
    );
    final Result<ReferenceDataset> saved = await ref
        .read(referenceRepositoryProvider)
        .importDataset(dataset: dataset, rows: rows);
    if (!mounted) {
      return;
    }
    switch (saved) {
      case FailureResult<ReferenceDataset>(:final Failure failure):
        setState(() {
          _saving = false;
          _saveFailure = failure;
        });
      case Success<ReferenceDataset>(:final ReferenceDataset value):
        final String? projectId = value.projectId;
        if (projectId != null && projectId.isNotEmpty) {
          context.go(RoutePaths.projectDataset(projectId, value.id));
        } else {
          context.pop();
        }
    }
  }
}
