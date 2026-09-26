import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/xlsx_encoder.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/exports/exports.dart';

import 'export_summary_view.dart';

/// Summarises what an export of [projectId] holds, writes one new workbook,
/// and shares it only on request.
final class ProjectExportScreen extends ConsumerStatefulWidget {
  /// Creates the export page for [projectId].
  const ProjectExportScreen({required this.projectId, super.key});

  /// Project whose records are written.
  final String projectId;

  @override
  ConsumerState<ProjectExportScreen> createState() =>
      _ProjectExportScreenState();
}

class _ProjectExportScreenState extends ConsumerState<ProjectExportScreen> {
  CancellationToken? _cancel;
  bool _busy = false;
  Failure? _failure;
  ExportedWorkbook? _saved;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ExportSummary> summary = ref.watch(
      _exportSummaryProvider(widget.projectId),
    );
    final bool offline = ref.watch(offlineNowProvider);
    final DownloadService downloads = ref.watch(downloadServiceProvider);
    final bool hasRecords = (summary.asData?.value.records ?? 0) > 0;
    return AppPage(
      key: const ValueKey<String>('route-project-export'),
      title: Copy.projectExportTitle,
      footer: _failure == null && (hasRecords || _saved != null)
          ? _footer(downloads)
          : null,
      body: AsyncValueView<ExportSummary>(
        value: summary,
        onRetry: () => ref.invalidate(_exportSummaryProvider(widget.projectId)),
        isEmpty: (ExportSummary loaded) =>
            loaded.records == 0 && _saved == null,
        empty: () => const AppEmptyState(
          icon: AppIcons.export,
          headline: Copy.projectExportEmptyHeadline,
          message: Copy.projectExportEmptyMessage,
        ),
        data: (ExportSummary loaded) {
          final Failure? failure = _failure;
          if (failure != null) {
            return AppErrorState(
              failure: failure,
              onRetry: () => setState(() => _failure = null),
            );
          }
          final ExportedWorkbook? saved = _saved;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (offline) ...<Widget>[
                const AppBanner(
                  message: Copy.offlineWorking,
                  icon: AppIcons.offline,
                  tone: SnackTone.info,
                ),
                const SizedBox(height: Space.x3),
              ],
              if (saved != null) ...<Widget>[
                AppBanner(
                  message: Copy.projectExportSaved(saved.fileName),
                  icon: AppIcons.success,
                  tone: SnackTone.success,
                ),
                const SizedBox(height: Space.x3),
              ],
              ExportSummaryView(
                summary: loaded,
                destination: downloads.destination,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Export before a save, Cancel while writing, and Share afterwards: the
  /// page's one primary action sits in reach (FE-SIMP-01).
  Widget _footer(DownloadService downloads) {
    final ExportedWorkbook? saved = _saved;
    if (saved != null) {
      return AppPrimaryAction(
        label: Copy.projectExportShare,
        caption: downloads.canShareToApps ? Copy.projectExportShareHint : null,
        onPressed: () => unawaited(_share(saved)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_busy) ...<Widget>[
          AppButton(
            label: Copy.projectExportCancel,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: _stop,
          ),
          const SizedBox(height: Space.x2),
        ],
        AppPrimaryAction(
          label: Copy.projectExport,
          busy: _busy,
          caption: _busy ? Copy.projectExportProgress : null,
          onPressed: _busy ? null : () => unawaited(_export()),
        ),
      ],
    );
  }

  Future<void> _export() async {
    final ExportRepository? repository = ref.read(exportRepositoryProvider);
    if (repository == null) {
      setState(() => _failure = _filesUnavailable);
      return;
    }
    final CancellationToken cancel = CancellationToken();
    setState(() {
      _cancel = cancel;
      _busy = true;
      _failure = null;
    });
    final Result<ExportedWorkbook> written = await repository.exportProject(
      widget.projectId,
      cancel: cancel,
    );
    if (!mounted) {
      return;
    }
    switch (written) {
      case FailureResult<ExportedWorkbook>(:final Failure failure):
        setState(() {
          _busy = false;
          _cancel = null;
          _failure = failure is CancelledFailure ? null : failure;
        });
      case Success<ExportedWorkbook>(:final ExportedWorkbook value):
        setState(() {
          _busy = false;
          _cancel = null;
          _saved = value;
        });
        final Result<String?> copy = await ref
            .read(downloadServiceProvider)
            .save(
              fileName: value.fileName,
              bytes: value.bytes,
              mimeType: XlsxEncoder.mimeType,
              subfolder: 'Exports',
            );
        if (!mounted) {
          return;
        }
        if (copy is FailureResult<String?>) {
          showAppSnack(context, copy.failure.message, tone: SnackTone.error);
        }
    }
  }

  /// Opens the share sheet. A dismissed sheet says nothing; any other
  /// failure says why (FE-CONS-11).
  Future<void> _share(ExportedWorkbook saved) async {
    final Result<void> shared = await ref
        .read(downloadServiceProvider)
        .openExternally(
          fileName: saved.fileName,
          bytes: saved.bytes,
          mimeType: XlsxEncoder.mimeType,
        );
    if (!mounted) {
      return;
    }
    if (shared case FailureResult<void>(
      :final Failure failure,
    ) when failure is! CancelledFailure) {
      showAppSnack(context, failure.message, tone: SnackTone.error);
    }
  }

  void _stop() {
    _cancel?.cancel();
  }
}

/// The export summary for a project. With no export store on this device,
/// the page says the project files are not here.
final _exportSummaryProvider = StreamProvider.autoDispose
    .family<ExportSummary, String>((Ref ref, String projectId) {
      final ExportRepository? repository = ref.watch(exportRepositoryProvider);
      if (repository == null) {
        return Stream<ExportSummary>.error(_filesUnavailable);
      }
      return repository.watchSummary(projectId);
    }, retry: (int _, Object _) => null);

const StorageFailure _filesUnavailable = StorageFailure(
  message: 'Project files are not available on this device.',
  recoveryAction: 'Export from a device that stores this project.',
);
