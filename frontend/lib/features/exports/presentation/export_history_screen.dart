import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import 'export_share_action.dart';

/// Past exports: who made them, what they held, and a way to share again.
final class ExportHistoryScreen extends StatelessWidget {
  /// Creates the history. An empty [entries] list is the empty state.
  const ExportHistoryScreen({
    this.entries = const <ExportHistoryRow>[],
    this.loading = false,
    this.failure,
    this.onShare,
    this.onRerun,
    super.key,
  });

  /// Newest first.
  final List<ExportHistoryRow> entries;

  /// Whether history is still loading.
  final bool loading;

  /// Why history could not be read.
  final Failure? failure;

  /// Shares a file that is still on disk.
  final ValueChanged<String>? onShare;

  /// Re-runs the stored request when the file is missing.
  final ValueChanged<String>? onRerun;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: localCopy.exportHistoryTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return AppPage(
        title: localCopy.exportHistoryTitle,
        body: const SizedBox.shrink(),
      );
    }
    if (entries.isEmpty) {
      return AppPage(
        title: localCopy.exportHistoryTitle,
        body: AppEmptyState(
          icon: AppIcons.history,
          headline: localCopy.exportHistoryEmpty,
          message: localCopy.exportHistoryEmptyMessage,
        ),
      );
    }
    return AppPage(
      title: localCopy.exportHistoryTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final ExportHistoryRow entry in entries)
            AppListTile(
              key: ValueKey<String>('export-history-${entry.id}'),
              title: entry.folder,
              subtitle: '${entry.operatorName} · ${entry.recordCount}',
              onTap: () {},
            ),
          for (final ExportHistoryRow entry in entries)
            ExportShareAction(
              path: entry.path,
              missing: entry.missing,
              onShare: onShare,
              onRerun: () => onRerun?.call(entry.id),
            ),
        ],
      ),
    );
  }
}

/// One history row. [filters] is the query, never the exported values.
typedef ExportHistoryRow = ({
  String id,
  String folder,
  String operatorName,
  int recordCount,
  String path,
  bool missing,
});
