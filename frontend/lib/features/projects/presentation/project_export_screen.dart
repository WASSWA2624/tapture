import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
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
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/exports/exports.dart';

import 'export_summary_view.dart';

/// Writes one canonical project package; native handoff is explicit and
/// browser handoff retries the completed bytes without generating again.
final class ProjectExportScreen extends ConsumerStatefulWidget {
  /// Creates the export page for [projectId].
  const ProjectExportScreen({
    required this.projectId,
    this.startExport = false,
    super.key,
  });

  /// Project whose records are written.
  final String projectId;

  /// Menu intent consumed once by this mounted route, including Back revisits.
  final bool startExport;

  @override
  ConsumerState<ProjectExportScreen> createState() =>
      _ProjectExportScreenState();
}

class _ProjectExportScreenState extends ConsumerState<ProjectExportScreen>
    with StateRefresh {
  CancellationToken? _cancel;
  bool _busy = false;
  Failure? _failure;
  ExportedPackage? _saved;
  bool _summaryExpanded = false;
  bool _handoffBusy = false;
  Failure? _handoffFailure;

  @override
  void initState() {
    super.initState();
    if (widget.startExport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_export());
      });
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

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
      title: localCopy.projectExportTitle,
      overflow: <AppOverflowAction>[
        if (!_busy && !_handoffBusy)
          AppOverflowAction(
            key: const ValueKey<String>('project-export-deliverables'),
            label: localCopy.exportOutputFiles,
            icon: AppIcons.export,
            onTap: () =>
                context.go(RoutePaths.projectDeliverables(widget.projectId)),
          ),
      ],
      footer: _failure == null && (hasRecords || _saved != null || _busy)
          ? _footer(downloads)
          : null,
      body: AsyncValueView<ExportSummary>(
        value: summary,
        onRetry: () => ref.invalidate(_exportSummaryProvider(widget.projectId)),
        isEmpty: (ExportSummary loaded) =>
            loaded.records == 0 && _saved == null,
        empty: () => AppEmptyState(
          icon: AppIcons.export,
          headline: Copy.of(context).projectExportEmptyHeadline,
          message: Copy.of(context).projectExportEmptyMessage,
          actionLabel: Copy.of(context).recordsEmptyAction,
          onAction: () =>
              context.go(RoutePaths.projectCapture(widget.projectId)),
        ),
        data: (ExportSummary loaded) {
          final LocalizedCopy localCopy = Copy.of(context);

          final Failure? failure = _failure;
          if (failure != null) {
            return AppErrorState(
              failure: failure,
              onRetry: () => unawaited(_export()),
            );
          }
          final ExportedPackage? saved = _saved;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (offline) ...<Widget>[
                AppBanner(
                  message: localCopy.offlineWorking,
                  icon: AppIcons.offline,
                  tone: SnackTone.info,
                ),
                const SizedBox(height: Space.x3),
              ],
              if (saved != null) ...<Widget>[
                AppBanner(
                  message: localCopy.projectExportSaved(saved.fileName),
                  icon: AppIcons.success,
                  tone: SnackTone.success,
                ),
                const SizedBox(height: Space.x3),
                ExportPrivacySummaryView(exportId: saved.id, package: true),
              ],
              if (_handoffFailure case final Failure failure)
                AppErrorState(
                  failure: failure,
                  onRetry: _handoffBusy || saved == null
                      ? null
                      : () => unawaited(_download(saved)),
                ),
              AppSectionHeader(
                key: const ValueKey<String>('project-export-summary'),
                title: localCopy.projectExportDetails,
                expanded: _summaryExpanded,
                onToggle: () =>
                    refresh(() => _summaryExpanded = !_summaryExpanded),
              ),
              if (_summaryExpanded)
                ExportSummaryView(
                  summary: loaded,
                  destination: kIsWeb || saved?.package is InMemoryBundle
                      ? localCopy.projectExportBrowserDestination
                      : localCopy.projectExportDestination,
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
  Widget? _footer(DownloadService downloads) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ExportedPackage? saved = _saved;
    if (saved != null) {
      if (saved.package is InMemoryBundle) return null;
      return AppPrimaryAction(
        label: downloads.canShareToApps
            ? localCopy.projectExportShare
            : localCopy.projectExportOpen,
        busy: _handoffBusy,
        caption: downloads.canShareToApps
            ? localCopy.projectExportShareHint
            : null,
        onPressed: _handoffBusy ? null : () => unawaited(_share(saved)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_busy) ...<Widget>[
          AppButton(
            label: localCopy.projectExportCancel,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: _stop,
          ),
          const SizedBox(height: Space.x2),
        ],
        AppPrimaryAction(
          label: localCopy.projectExport,
          busy: _busy,
          caption: _busy ? localCopy.projectExportProgress : null,
          onPressed: _busy ? null : () => unawaited(_export()),
        ),
      ],
    );
  }

  Future<void> _export() async {
    if (_busy || _saved != null) return;
    final ExportRepository? store = ref.read(exportRepositoryProvider);
    if (store == null) {
      refresh(() => _failure = _filesUnavailable);
      return;
    }
    final CancellationToken cancel = CancellationToken();
    refresh(() {
      _cancel = cancel;
      _busy = true;
      _failure = null;
    });
    final Result<ExportedPackage> written = await store.exportProject(
      widget.projectId,
      cancel: cancel,
    );
    if (!mounted) {
      return;
    }
    switch (written) {
      case FailureResult<ExportedPackage>(:final Failure failure):
        refresh(() {
          _busy = false;
          _cancel = null;
          _failure = failure is CancelledFailure ? null : failure;
        });
      case Success<ExportedPackage>(:final ExportedPackage value):
        refresh(() {
          _busy = false;
          _cancel = null;
          _saved = value;
        });
        if (value.package is InMemoryBundle) await _download(value);
    }
  }

  /// Opens the share sheet. A dismissed sheet says nothing; any other
  /// failure says why (FE-CONS-11).
  Future<void> _share(ExportedPackage saved) async {
    if (_handoffBusy) return;
    refresh(() => _handoffBusy = true);
    try {
      await _shareSaved(saved);
    } finally {
      if (mounted) refresh(() => _handoffBusy = false);
    }
  }

  Future<void> _download(ExportedPackage saved) async {
    if (_handoffBusy) return;
    final BundleOutput package = saved.package;
    if (package is! InMemoryBundle) return;
    refresh(() => _handoffBusy = true);
    try {
      final ExportRepository? store = ref.read(exportRepositoryProvider);
      if (store case final ExportSharingPolicy policy) {
        final Result<void> allowed = await policy.allowShare(saved.id);
        if (!mounted) return;
        if (allowed case FailureResult<void>(:final Failure failure)) {
          refresh(() => _handoffFailure = failure);
          return;
        }
      }
      final Result<String?> copied = await ref
          .read(downloadServiceProvider)
          .save(
            fileName: saved.fileName,
            bytes: package.bytes,
            mimeType: BundleFormat.mimeType,
          );
      if (!mounted) return;
      refresh(
        () => _handoffFailure = switch (copied) {
          FailureResult<String?>(:final Failure failure) => failure,
          Success<String?>() => null,
        },
      );
    } finally {
      if (mounted) refresh(() => _handoffBusy = false);
    }
  }

  Future<void> _shareSaved(ExportedPackage saved) async {
    final ExportRepository? store = ref.read(exportRepositoryProvider);
    if (store case final ExportSharingPolicy policy) {
      final Result<void> allowed = await policy.allowShare(saved.id);
      if (!mounted) return;
      if (allowed case FailureResult<void>(:final Failure failure)) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
        return;
      }
    }
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
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
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
      final ExportRepository? store = ref.watch(exportRepositoryProvider);
      if (store == null) {
        return Stream<ExportSummary>.error(_filesUnavailable);
      }
      return store.watchSummary(projectId);
    }, retry: (int _, Object _) => null);

/// How big the project's package is expected to be; nothing while unknown.
final _packageEstimateProvider = FutureProvider.autoDispose
    .family<int?, String>((Ref ref, String projectId) async {
      final ExportRepository? store = ref.watch(exportRepositoryProvider);
      if (store == null) {
        return null;
      }
      return switch (await store.estimatePackage(projectId)) {
        Success<int>(:final int value) => value,
        FailureResult<int>() => null,
      };
    }, retry: (int _, Object _) => null);

final StorageFailure _filesUnavailable = StorageFailure(
  localizedMessage: Copy.messages.failureProjectFilesAreNotAvailableOnThis,
  localizedRecovery: Copy.messages.failureExportFromADeviceThatStoresThis,
);
