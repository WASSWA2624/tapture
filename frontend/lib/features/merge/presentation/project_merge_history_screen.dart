import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/merge_history_entry.dart';
import 'merge_history_controller.dart';

/// The production history route: stored provenance, counts and retained undo.
final class ProjectMergeHistoryScreen extends ConsumerWidget {
  /// Shows durable merge history for the selected project.
  const ProjectMergeHistoryScreen({required this.projectId, super.key});

  /// Project whose packages and merges are shown.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Set<String> busy = ref.watch(mergeHistoryControllerProvider);
    return AppPage(
      key: const ValueKey<String>('route-project-merge-history'),
      title: localCopy.mergeHistoryTitle,
      scrollable: false,
      body: AsyncValueView<List<MergeHistoryEntry>>(
        value: ref.watch(mergeHistoryProvider(projectId)),
        isEmpty: (List<MergeHistoryEntry> rows) => rows.isEmpty,
        onRetry: () => ref.invalidate(mergeHistoryProvider(projectId)),
        empty: () => AppEmptyState(
          icon: AppIcons.history,
          headline: Copy.of(context).mergeHistoryEmpty,
          message: Copy.of(context).mergeHistoryEmptyMessage,
          actionLabel: Copy.of(context).importTitle,
          onAction: () => context.go(RoutePaths.projectImport),
        ),
        data: (List<MergeHistoryEntry> rows) => ListView.builder(
          itemCount: rows.length,
          padding: const EdgeInsets.all(Space.x4),
          itemBuilder: (BuildContext context, int index) {
            final LocalizedCopy localCopy = Copy.of(context);

            final MergeHistoryEntry entry = rows[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppListTile(
                  key: ValueKey<String>('merge-history-${entry.id}'),
                  title: entry.sourceDevice,
                  subtitle: <String>[
                    localCopy.mergeHistoryFacts(
                      entry.bundleName,
                      entry.bundleId,
                      entry.at,
                      entry.status,
                    ),
                    for (final MapEntry<String, int> count
                        in entry.counts.entries)
                      localCopy.mergeHistoryCount(count.key, count.value),
                    for (final MapEntry<String, int> choice
                        in entry.resolutions.entries)
                      localCopy.mergeHistoryResolution(
                        choice.key,
                        choice.value,
                      ),
                  ].join('\n'),
                ),
                if (entry.undoUntil case final DateTime until)
                  AppButton(
                    key: ValueKey<String>('merge-undo-${entry.id}'),
                    label: localCopy.mergeUndoDeadline(until),
                    busy: busy.contains(entry.id),
                    variant: AppButtonVariant.secondary,
                    onPressed: busy.contains(entry.id)
                        ? null
                        : () => unawaited(_undo(context, ref, entry.id)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _undo(BuildContext context, WidgetRef ref, String id) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.undo,
      message: localCopy.mergeUndoConfirm,
      confirmLabel: localCopy.undo,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final Result<void> restored = await ref
        .read(mergeHistoryControllerProvider.notifier)
        .undo(id);
    if (!context.mounted) {
      return;
    }
    switch (restored) {
      case Success<void>():
        showAppSnack(context, localCopy.mergeUndoDone, tone: SnackTone.success);
      case FailureResult<void>(:final failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
    }
  }
}
