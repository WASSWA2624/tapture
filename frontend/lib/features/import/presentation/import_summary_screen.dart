import 'dart:async';

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show currentProjectProvider;

import '../domain/record_import.dart';
import 'record_import_controller.dart';

/// What a record import did (task 020 step 5): rows grouped by outcome,
/// created, updated, skipped and failed, each by its spreadsheet row
/// number and every skipped or failed row with its reason. Retry runs only
/// the failed rows again; the skipped and failed rows export as a file to
/// correct and import again.
final class ImportSummaryScreen extends ConsumerWidget {
  /// Creates the summary of the record import in progress.
  const ImportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordImportView view = ref.watch(recordImportControllerProvider);
    final RecordImportController controller = ref.read(
      recordImportControllerProvider.notifier,
    );
    final RecordImportResult? result = view.result;
    final Failure? failure = view.failure;
    final Widget body;
    Widget? footer;
    if (view.running) {
      body = AppProgressSteps(
        key: const ValueKey<String>('import-running'),
        steps: <ProgressStep>[
          ProgressStep(
            label: localCopy.importWriting,
            state: StepState.running,
            detail: view.total == 0
                ? null
                : localCopy.importProgress(view.done, view.total),
          ),
        ],
      );
    } else if (failure != null) {
      body = AppErrorState(
        failure: failure,
        onRetry: () => context.go(RoutePaths.projectImportRecords),
      );
    } else if (result == null) {
      body = AppEmptyState(
        icon: AppIcons.import,
        headline: localCopy.importNoSheetHeadline,
        message: localCopy.importNoSheetMessage,
        actionLabel: localCopy.importChooseFile,
        onAction: () => context.go(RoutePaths.projectImport),
      );
    } else {
      body = _Outcomes(result: result);
      footer = _actions(context, ref, controller, result);
    }
    return AppPage(
      key: const ValueKey<String>('route-import-summary'),
      title: localCopy.importSummaryTitle,
      inset: false,
      scrollable: result == null || view.running,
      footer: footer,
      body: body,
    );
  }

  Widget _actions(
    BuildContext context,
    WidgetRef ref,
    RecordImportController controller,
    RecordImportResult result,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Set<int> failed = <int>{
      for (final RowFailure row in result.failures) row.row,
    };
    final bool problems = failed.isNotEmpty || result.skipped.isNotEmpty;
    final Widget primary = failed.isNotEmpty
        ? AppPrimaryAction(
            key: const ValueKey<String>('import-retry'),
            label: localCopy.importRetry,
            onPressed: () => unawaited(controller.retry(failed)),
          )
        : AppPrimaryAction(
            key: const ValueKey<String>('import-open-records'),
            label: localCopy.importOpenRecords,
            onPressed: () {
              final String? projectId = ref.read(currentProjectProvider);
              context.go(
                projectId == null
                    ? RoutePaths.records
                    : RoutePaths.projectRecords(projectId),
              );
            },
          );
    if (!problems) {
      return primary;
    }
    return ResponsivePair(
      start: primary,
      end: AppButton(
        key: const ValueKey<String>('import-export-problems'),
        label: localCopy.importExportProblems,
        variant: AppButtonVariant.secondary,
        expand: true,
        onPressed: () => unawaited(_export(context, controller)),
      ),
    );
  }
}

Future<void> _export(
  BuildContext context,
  RecordImportController controller,
) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final Result<String?> saved = await controller.exportProblems();
  if (!context.mounted) {
    return;
  }
  switch (saved) {
    case Success<String?>():
      showAppSnack(context, localCopy.importFixSaved, tone: SnackTone.success);
    case FailureResult<String?>(:final Failure failure):
      if (failure is! CancelledFailure) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      }
  }
}

/// The rows by outcome, in one lazily built list so a ten-thousand-row
/// import stays cheap to show.
class _Outcomes extends StatelessWidget {
  const _Outcomes({required this.result});

  final RecordImportResult result;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<Widget Function()> items = <Widget Function()>[
      if (result.failures.isEmpty && result.skipped.isEmpty)
        () => AppBanner(
          key: const ValueKey<String>('import-all-done'),
          message: Copy.of(context).importAllDone,
          icon: AppIcons.success,
          tone: SnackTone.success,
        ),
      ..._group(
        context,
        localCopy.importFailed(result.failures.length),
        'failed',
        <({int row, String? line})>[
          for (final RowFailure row in result.failures)
            (row: row.row, line: row.reason),
        ],
      ),
      ..._group(
        context,
        localCopy.importSkipped(result.skipped.length),
        'skipped',
        <({int row, String? line})>[
          for (final RowFailure row in result.skipped)
            (row: row.row, line: row.reason),
        ],
      ),
      ..._group(
        context,
        localCopy.importCreated(result.created.length),
        'created',
        <({int row, String? line})>[
          for (final ImportedRow row in result.created)
            (row: row.row, line: null),
        ],
      ),
      ..._group(
        context,
        localCopy.importUpdated(result.updated.length),
        'updated',
        <({int row, String? line})>[
          for (final ImportedRow row in result.updated)
            (row: row.row, line: null),
        ],
      ),
    ];
    return ListView.builder(
      key: const ValueKey<String>('import-outcomes'),
      itemCount: items.length,
      itemBuilder: (BuildContext _, int index) => items[index](),
    );
  }

  /// A heading over [rows], or nothing when there are none.
  static List<Widget Function()> _group(
    BuildContext context,
    String title,
    String outcome,
    List<({int row, String? line})> rows,
  ) {
    if (rows.isEmpty) {
      return const <Widget Function()>[];
    }
    return <Widget Function()>[
      () => AppSectionHeader(
        key: ValueKey<String>('import-$outcome'),
        title: title,
      ),
      for (final ({int row, String? line}) row in rows)
        () => AppListTile(
          key: ValueKey<String>('import-$outcome-${row.row}'),
          title: Copy.of(context).importRow(row.row),
          subtitle: row.line,
        ),
    ];
  }
}
