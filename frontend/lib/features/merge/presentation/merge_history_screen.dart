import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Past merges, with the undo deadline while the snapshot still exists.
final class MergeHistoryScreen extends StatelessWidget {
  /// Creates the history. An empty [entries] list is the empty state.
  const MergeHistoryScreen({
    this.entries = const <MergeHistoryRow>[],
    this.loading = false,
    this.failure,
    this.onUndo,
    super.key,
  });

  /// Newest first.
  final List<MergeHistoryRow> entries;

  /// Whether history is still loading.
  final bool loading;

  /// Why history could not be read.
  final Failure? failure;

  /// Restores the snapshot for a merge id.
  final ValueChanged<String>? onUndo;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.mergeHistoryTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return const AppPage(
        title: Copy.mergeHistoryTitle,
        body: SizedBox.shrink(),
      );
    }
    if (entries.isEmpty) {
      return const AppPage(
        title: Copy.mergeHistoryTitle,
        body: AppEmptyState(
          icon: AppIcons.history,
          headline: Copy.mergeHistoryEmpty,
          message: Copy.mergeHistoryEmptyMessage,
        ),
      );
    }
    return AppPage(
      title: Copy.mergeHistoryTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final MergeHistoryRow entry in entries) ...<Widget>[
            AppListTile(
              key: ValueKey<String>('merge-history-${entry.id}'),
              title: entry.sourceDevice,
              subtitle:
                  '${entry.bundleId} · ${entry.recordCount} · ${entry.resolved}',
            ),
            if (entry.undoUntil != null)
              AppButton(
                key: ValueKey<String>('merge-undo-${entry.id}'),
                label: Copy.mergeUndoUntil(entry.undoUntil!),
                variant: AppButtonVariant.secondary,
                onPressed: () => onUndo?.call(entry.id),
              ),
          ],
        ],
      ),
    );
  }
}

/// One merge. [undoUntil] is null once the snapshot is purged.
typedef MergeHistoryRow = ({
  String id,
  String sourceDevice,
  String bundleId,
  int recordCount,
  int resolved,
  String? undoUntil,
});
