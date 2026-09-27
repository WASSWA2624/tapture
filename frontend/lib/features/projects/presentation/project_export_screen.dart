import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/bundle/bundle_format.dart';
import 'package:tapture/core/bundle/bundle_output.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
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

/// Summarises what an export of [projectId] holds and how big its package
/// will be, writes one new project package, and shares it only on request
/// (task 076, D13). On a device the stored package is copied in chunks; a
/// browser hands over the bytes it built (D6).
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
  ExportedPackage? _saved;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ExportSummary> summary = ref.watch(
      _exportSummaryProvider(widget.projectId),
    );
    final bool offline = ref.watch(offlineNowProvider);
    final DownloadService downloads = ref.watch(downloadServiceProvider);
    final bool hasRecords = (summary.asData?.value.records ?? 0) > 0;
    final int? estimate = ref
        .watch(_packageEstimateProvider(widget.projectId))
        .asData
        ?.value;
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
          final ExportedPackage? saved = _saved;
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
                estimatedBytes: saved == null ? estimate : null,
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
    final ExportedPackage? saved = _saved;
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
    final Result<ExportedPackage> written = await repository.exportProject(
      widget.projectId,
      cancel: cancel,
    );
    if (!mounted) {
      return;
    }
    switch (written) {
      case FailureResult<ExportedPackage>(:final Failure failure):
        setState(() {
          _busy = false;
          _cancel = null;
          _failure = failure is CancelledFailure ? null : failure;
        });
      case Success<ExportedPackage>(:final ExportedPackage value):
        setState(() {
          _busy = false;
          _cancel = null;
          _saved = value;
        });
        final DownloadService downloads = ref.read(downloadServiceProvider);
        final Result<String?> copy = switch (value.package) {
          StoredBundle(:final String relativePath) =>
            await downloads.saveStored(
              relativePath: relativePath,
              fileName: value.fileName,
              mimeType: BundleFormat.mimeType,
              subfolder: 'Exports',
            ),
          InMemoryBundle(:final Uint8List bytes) => await downloads.save(
            fileName: value.fileName,
            bytes: bytes,
            mimeType: BundleFormat.mimeType,
            subfolder: 'Exports',
          ),
        };
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
  Future<void> _share(ExportedPackage saved) async {
    final DownloadService downloads = ref.read(downloadServiceProvider);
    final Result<void> shared = switch (saved.package) {
      StoredBundle(:final String relativePath) =>
        await downloads.openStoredExternally(
          relativePath: relativePath,
          fileName: saved.fileName,
          mimeType: BundleFormat.mimeType,
        ),
      InMemoryBundle(:final Uint8List bytes) => await downloads.openExternally(
        fileName: saved.fileName,
        bytes: bytes,
        mimeType: BundleFormat.mimeType,
      ),
    };
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

/// How big the project's package is expected to be; nothing while unknown.
final _packageEstimateProvider = FutureProvider.autoDispose
    .family<int?, String>((Ref ref, String projectId) async {
      final ExportRepository? repository = ref.watch(exportRepositoryProvider);
      if (repository == null) {
        return null;
      }
      return switch (await repository.estimatePackage(projectId)) {
        Success<int>(:final int value) => value,
        FailureResult<int>() => null,
      };
    }, retry: (int _, Object _) => null);

const StorageFailure _filesUnavailable = StorageFailure(
  message: 'Project files are not available on this device.',
  recoveryAction: 'Export from a device that stores this project.',
);
