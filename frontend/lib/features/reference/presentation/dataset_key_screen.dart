import 'dart:async';

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/dataset_import_draft.dart';
import '../domain/reference_dataset.dart';
import 'dataset_import_controller.dart';

/// Ends every import (task 010 step 3): each parsed column with its
/// duplicate count and first values, the chosen key, and the colliding
/// values when that key repeats. A repeating key is saved only after the
/// operator confirms it.
class DatasetKeyScreen extends ConsumerWidget {
  /// Creates the key-column screen for [draft], or one that asks for a file
  /// when [draft] is null. [projectId] owns the imported dataset.
  const DatasetKeyScreen({super.key, this.draft, this.projectId});

  /// Parsed import ready to save. Null asks for a file.
  final DatasetImportDraft? draft;

  /// Project the dataset is imported into; the open one when null.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final DatasetImportView view = ref.watch(
      datasetImportControllerProvider(draft),
    );
    final DatasetImportController controller = ref.read(
      datasetImportControllerProvider(draft).notifier,
    );
    final String? project =
        _present(projectId) ?? _present(ref.watch(currentProjectProvider));
    void pick() => unawaited(controller.pick(projectId: project));
    if (view.reading) {
      return AppPage(
        key: const ValueKey<String>('route-dataset-import'),
        title: localCopy.datasetsImport,
        body: AppProgressSteps(
          steps: <ProgressStep>[
            ProgressStep(
              label: localCopy.datasetsReading,
              state: StepState.running,
              detail: localCopy.datasetsReadProgress(
                (view.progress * 100).round(),
              ),
            ),
          ],
        ),
      );
    }
    final DatasetImportDraft? current = view.draft;
    if (current == null) {
      final Failure? failure = view.failure;
      return AppPage(
        key: const ValueKey<String>('route-dataset-import'),
        title: localCopy.datasetsImport,
        body: failure == null
            ? AppEmptyState(
                icon: AppIcons.dataset,
                headline: localCopy.datasetsPickHeadline,
                message: localCopy.datasetsPickMessage,
                actionLabel: localCopy.datasetsPickFile,
                onAction: pick,
              )
            : AppErrorState(failure: failure, onRetry: pick),
      );
    }
    final String key = view.keyColumn ?? current.dataset.keyColumn;
    final int duplicates = current.duplicateCounts[key] ?? 0;
    final Failure? failure = view.failure;
    return AppPage(
      key: const ValueKey<String>('route-dataset-import'),
      title: localCopy.datasetsKeyTitle,
      inset: false,
      scrollable: false,
      footer: AppPrimaryAction(
        label: duplicates > 0
            ? localCopy.datasetsAllowDuplicates
            : localCopy.datasetsSaveImport,
        busy: view.saving,
        onPressed: () =>
            unawaited(_save(context, controller, key, duplicates, project)),
      ),
      body: ListView(
        key: const ValueKey<String>('dataset-key-columns'),
        children: <Widget>[
          AppBanner(
            message: localCopy.datasetsKeyMessage,
            icon: AppIcons.info,
            tone: SnackTone.info,
          ),
          if (failure != null)
            AppBanner(
              message: failure.message,
              icon: AppIcons.error,
              tone: SnackTone.error,
            ),
          if (duplicates > 0)
            AppBanner(
              key: const ValueKey<String>('dataset-key-duplicates'),
              message: localCopy.datasetsDuplicateWarning(
                duplicates,
                current.collisions[key] ?? const <String>[],
              ),
              icon: AppIcons.warning,
              tone: SnackTone.warning,
            ),
          for (final String column in current.dataset.columns)
            AppListTile(
              key: ValueKey<String>('dataset-key-$column'),
              title: column,
              subtitle: localCopy.datasetsColumnSummary(
                current.duplicateCounts[column] ?? 0,
                (current.samples[column] ?? const <String>[]).take(2).toList(),
              ),
              selected: column == key,
              onTap: () => controller.chooseKey(column),
            ),
        ],
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    DatasetImportController controller,
    String key,
    int duplicates,
    String? project,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    if (duplicates > 0) {
      final bool confirmed = await showAppConfirm(
        context,
        title: localCopy.datasetsDuplicatesConfirmTitle,
        message: localCopy.datasetsDuplicatesConfirm(key, duplicates),
        confirmLabel: localCopy.datasetsAllowDuplicates,
      );
      if (!confirmed) {
        return;
      }
    }
    final ReferenceDataset? saved = await controller.save();
    if (saved == null || !context.mounted) {
      return;
    }
    final String? owner = _present(saved.projectId) ?? project;
    if (owner != null) {
      context.go(RoutePaths.projectDataset(owner, saved.id));
    } else {
      context.pop();
    }
  }
}

String? _present(String? id) => id == null || id.isEmpty ? null : id;
