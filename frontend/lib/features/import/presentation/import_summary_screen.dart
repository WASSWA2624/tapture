import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import '../domain/record_import.dart';

/// What an import did, and a way to retry only the failures.
final class ImportSummaryScreen extends StatelessWidget {
  /// Creates the summary. A null [result] is the empty state.
  const ImportSummaryScreen({
    this.result,
    this.loading = false,
    this.failure,
    this.onRetry,
    this.onExport,
    super.key,
  });

  /// The finished import.
  final RecordImportResult? result;

  /// Whether the import is still running.
  final bool loading;

  /// Why the summary could not be read.
  final Failure? failure;

  /// Re-runs only [RecordImportResult.failures].
  final ValueChanged<Set<int>>? onRetry;

  /// Writes the skipped and failed rows.
  final ValueChanged<String>? onExport;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.importSummaryTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return const AppPage(
        title: Copy.importSummaryTitle,
        body: SizedBox.shrink(),
      );
    }
    final RecordImportResult? loaded = result;
    if (loaded == null) {
      return const AppPage(
        title: Copy.importSummaryTitle,
        body: AppEmptyState(
          icon: AppIcons.import,
          headline: Copy.importEmptyHeadline,
          message: Copy.importEmptyMessage,
        ),
      );
    }
    return AppPage(
      title: Copy.importSummaryTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(Copy.importCreated(loaded.created.length)),
          Text(Copy.importUpdated(loaded.updated.length)),
          Text(Copy.importSkipped(loaded.skipped.length)),
          Text(Copy.importFailed(loaded.failures.length)),
          for (final RowFailure row in loaded.failures)
            Text(
              Copy.importRowReason(row.row, row.reason),
              key: ValueKey<String>('import-failure-${row.row}'),
            ),
          for (final RowFailure row in loaded.skipped)
            Text(
              Copy.importRowReason(row.row, row.reason),
              key: ValueKey<String>('import-skipped-${row.row}'),
            ),
          if (loaded.failures.isNotEmpty)
            AppButton(
              key: const ValueKey<String>('import-retry'),
              label: Copy.importRetry,
              onPressed: () => onRetry?.call(<int>{
                for (final RowFailure row in loaded.failures) row.row,
              }),
            ),
          if (loaded.skipped.isNotEmpty || loaded.failures.isNotEmpty)
            AppButton(
              key: const ValueKey<String>('import-export-problems'),
              label: Copy.importExportProblems,
              variant: AppButtonVariant.secondary,
              onPressed: () =>
                  onExport?.call(RecordImport.correctiveList(loaded)),
            ),
        ],
      ),
    );
  }
}
