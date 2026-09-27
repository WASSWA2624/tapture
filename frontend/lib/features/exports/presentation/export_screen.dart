import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import 'export_options_section.dart';
import 'export_progress.dart';
import 'export_scope_section.dart';

/// The deliverable export: remembered options, one tap, then progress.
final class ExportScreen extends StatelessWidget {
  /// Creates the screen. [columns] are the project's last choice.
  const ExportScreen({
    this.scope,
    this.count,
    this.columns = (
      raw: false,
      refined: true,
      confidence: false,
      evidence: false,
    ),
    this.running = false,
    this.loading = false,
    this.failure,
    this.stages = const <ExportStage>[],
    this.onScope,
    this.onColumns,
    this.onExport,
    this.onCancel,
    super.key,
  });

  /// Chosen scope.
  final ExportScopeKind? scope;

  /// Live count for [scope].
  final int? count;

  /// Remembered columns. Refined starts on.
  final ExportColumns columns;

  /// Whether a job is in progress.
  final bool running;

  /// Whether the screen is still loading.
  final bool loading;

  /// Why the screen could not open.
  final Failure? failure;

  /// Progress stages while [running].
  final List<ExportStage> stages;

  /// Changes the scope.
  final ValueChanged<ExportScopeKind>? onScope;

  /// Stores column choices.
  final ValueChanged<ExportColumns>? onColumns;

  /// Starts the export. One tap when options are already applied.
  final VoidCallback? onExport;

  /// Cancels and drops partial files.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.exportTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return const AppPage(title: Copy.exportTitle, body: SizedBox.shrink());
    }
    if (scope == null && count == null && !running) {
      return const AppPage(
        title: Copy.exportTitle,
        body: AppEmptyState(
          icon: AppIcons.export,
          headline: Copy.exportEmptyHeadline,
          message: Copy.exportEmptyMessage,
        ),
      );
    }
    return AppPage(
      key: const ValueKey<String>('route-export'),
      title: Copy.exportTitle,
      footer: running
          ? null
          : AppButton(
              key: const ValueKey<String>('export-run'),
              label: Copy.exportRun,
              expand: true,
              onPressed: onExport,
            ),
      body: running
          ? ExportProgress(stages: stages, onCancel: onCancel)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ExportScopeSection(
                  selected: scope,
                  count: count,
                  onSelect: onScope,
                ),
                ExportOptionsSection(columns: columns, onChanged: onColumns),
              ],
            ),
    );
  }
}
