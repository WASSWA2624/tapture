import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/xlsx_encoder.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/exports/exports.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectRepositoryProvider;

/// Writes one new workbook for [projectId] and shares it only on request.
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
    final AsyncValue<List<ProjectRecordRow>> records = ref.watch(
      _exportRecordsProvider(widget.projectId),
    );
    final bool offline = ref.watch(projectExportOfflineProvider);
    return AppPage(
      key: const ValueKey<String>('route-project-export'),
      title: Copy.projectExportTitle,
      body: AsyncValueView<List<ProjectRecordRow>>(
        value: records,
        onRetry: () => ref.invalidate(_exportRecordsProvider(widget.projectId)),
        isEmpty: (List<ProjectRecordRow> rows) =>
            rows.isEmpty && _saved == null,
        empty: () => const AppEmptyState(
          icon: AppIcons.export,
          headline: Copy.projectExportEmptyHeadline,
          message: Copy.projectExportEmptyMessage,
        ),
        data: (List<ProjectRecordRow> rows) {
          final Failure? failure = _failure;
          if (failure != null) {
            return AppErrorState(
              failure: failure,
              onRetry: () => setState(() => _failure = null),
            );
          }
          final ExportedWorkbook? saved = _saved;
          if (saved != null) {
            return _SavedExport(saved: saved, offline: offline);
          }
          return _ExportReady(
            count: rows.length,
            busy: _busy,
            offline: offline,
            onExport: _export,
            onCancel: _busy ? _stop : null,
          );
        },
      ),
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

  void _stop() {
    _cancel?.cancel();
  }
}

class _ExportReady extends StatelessWidget {
  const _ExportReady({
    required this.count,
    required this.busy,
    required this.offline,
    required this.onExport,
    required this.onCancel,
  });

  final int count;
  final bool busy;
  final bool offline;
  final VoidCallback onExport;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (offline) ...<Widget>[
          const Text(Copy.offlineWorking),
          const SizedBox(height: Space.x2),
        ],
        Text(Copy.projectRecordPhotos(count)),
        const SizedBox(height: Space.x2),
        if (busy) ...<Widget>[
          const Text(Copy.projectExportProgress),
          const SizedBox(height: Space.x2),
          AppButton(
            label: Copy.projectExportCancel,
            variant: AppButtonVariant.secondary,
            onPressed: onCancel,
          ),
        ] else
          AppButton(
            label: Copy.projectExport,
            icon: AppIcons.export,
            onPressed: onExport,
          ),
      ],
    );
  }
}

class _SavedExport extends ConsumerWidget {
  const _SavedExport({required this.saved, required this.offline});

  final ExportedWorkbook saved;
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (offline) ...<Widget>[
          const Text(Copy.offlineWorking),
          const SizedBox(height: Space.x2),
        ],
        const Text(Copy.projectExportWrote, style: AppText.title),
        const SizedBox(height: Space.x1),
        Text(saved.fileName),
        const SizedBox(height: Space.x2),
        AppPrimaryAction(
          label: Copy.projectExportShare,
          onPressed: () => unawaited(_share(ref)),
        ),
      ],
    );
  }

  Future<void> _share(WidgetRef ref) {
    return ref
        .read(downloadServiceProvider)
        .openExternally(
          fileName: saved.fileName,
          bytes: saved.bytes,
          mimeType: XlsxEncoder.mimeType,
        );
  }
}

const List<String> _exportStatuses = <String>[
  'draft',
  'captured',
  'CAPTURED',
  'queued',
  'processing',
  'needsReview',
  'approved',
  'failed',
  'archived',
  'extracted',
];

final _exportRecordsProvider =
    StreamProvider.family<List<ProjectRecordRow>, String>((
      Ref ref,
      String projectId,
    ) {
      return ref
          .watch(projectRepositoryProvider)
          .watchRecords(projectId, statuses: _exportStatuses);
    }, retry: (int _, Object _) => null);

/// True when this page should say the device is offline. The shell banner
/// watches the radio; tests override this flag.
final Provider<bool> projectExportOfflineProvider = Provider<bool>(
  (Ref _) => false,
);

const StorageFailure _filesUnavailable = StorageFailure(
  message: 'Project files are not available on this device.',
  recoveryAction: 'Export from a device that stores this project.',
);
