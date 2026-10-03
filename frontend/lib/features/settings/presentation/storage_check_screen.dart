import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
// The read-only report and its provider; the page never holds the database.
import 'package:tapture/core/db/integrity_check.dart'
    show IntegrityFinding, integrityCheckProvider;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/orphan_scanner.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show Project, currentProjectDetailsProvider;
import 'package:tapture/features/records/records.dart'
    show RecordFilter, RecordSort, RecordSummary, recordRepositoryProvider;

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Checks what the app keeps against what is there (tasks 004 and 005): the
/// database's own references, and the open project's folder against its
/// photo and attachment rows, both ways.
///
/// Nothing is deleted or moved. Marking a missing file and attaching a
/// stray one to a record are each a separate, confirmed choice (rule 1 of
/// the standard).
class StorageCheckScreen extends ConsumerWidget {
  /// Creates the check page.
  const StorageCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<_CheckView> value = ref.watch(storageCheckProvider);
    return AppPage(
      title: localCopy.storageCheckTitle,
      inset: false,
      body: AsyncValueView<_CheckView>(
        value: value,
        onRetry: () => ref.invalidate(storageCheckProvider),
        data: (_CheckView view) {
          final LocalizedCopy localCopy = Copy.of(context);

          final _StorageCheck check = ref.read(storageCheckProvider.notifier);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSectionHeader(title: localCopy.storageCheckDatabaseHeader),
              if (view.findings.isEmpty)
                AppListTile(
                  leading: const Icon(AppIcons.success),
                  title: localCopy.storageCheckDatabaseClean,
                )
              else
                for (final IntegrityFinding finding in view.findings)
                  AppListTile(
                    leading: const Icon(AppIcons.warning),
                    title: finding.detail,
                    subtitle: localCopy.storageCheckFindingRow(
                      finding.entityType,
                      finding.entityId,
                    ),
                  ),
              ..._files(context, view, check),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _files(
    BuildContext context,
    _CheckView view,
    _StorageCheck check,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Project? project = view.project;
    if (project == null) {
      return <Widget>[
        AppSectionHeader(title: localCopy.storageCheckStrayHeader),
        AppListTile(
          key: const ValueKey<String>('storage-check-no-project'),
          title: localCopy.storageCheckNoProject,
          trailing: const Icon(AppIcons.open),
          onTap: () => context.go(RoutePaths.projects),
        ),
      ];
    }
    final Failure? failure = view.filesFailure;
    final OrphanReport? report = view.report;
    return <Widget>[
      AppSectionHeader(
        title: localCopy.storageCheckProjectHeader(project.name),
      ),
      if (failure != null)
        AppBanner(
          message: Copy.of(context).failureMessage(failure),
          icon: AppIcons.error,
          tone: SnackTone.error,
        )
      else if (report != null &&
          report.filesWithoutRows.isEmpty &&
          report.rowsWithoutFiles.isEmpty)
        AppListTile(
          leading: const Icon(AppIcons.success),
          title: localCopy.storageCheckFilesClean,
        ),
      if (report != null && report.rowsWithoutFiles.isNotEmpty) ...<Widget>[
        AppSectionHeader(title: localCopy.storageCheckMissingHeader),
        for (final MissingFile row in report.rowsWithoutFiles)
          AppListTile(
            key: ValueKey<String>('storage-check-missing-${row.id}'),
            leading: const Icon(AppIcons.warning),
            title: row.expectedPath,
            subtitle: localCopy.storageCheckMissingSubtitle,
            onTap: () => unawaited(check.flagMissing(context, row)),
          ),
      ],
      if (report != null && report.filesWithoutRows.isNotEmpty) ...<Widget>[
        AppSectionHeader(title: localCopy.storageCheckStrayHeader),
        for (final OrphanFile file in report.filesWithoutRows)
          AppListTile(
            key: ValueKey<String>('storage-check-stray-${file.path}'),
            leading: const Icon(AppIcons.folder),
            title: file.path,
            subtitle: localCopy.storageCheckStraySubtitle(
              localCopy.fileSize(file.bytes),
            ),
            onTap: () => unawaited(_attach(context, check, project.id, file)),
          ),
      ],
    ];
  }

  Future<void> _attach(
    BuildContext context,
    _StorageCheck check,
    String projectId,
    OrphanFile file,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? recordId = await showAppSheet<String>(
      context,
      title: localCopy.storageCheckAttachTitle,
      builder: (BuildContext _) => _RecordChoice(projectId: projectId),
    );
    if (recordId == null || !context.mounted) {
      return;
    }
    await check.attach(context, file, recordId: recordId);
  }
}

/// Injects the check's seams so a suite never walks a real folder
/// (FE-TEST-03): the scanner, the database check, and the open project.
Override storageCheckOverride({
  OrphanScanner? scanner,
  Future<Result<List<IntegrityFinding>>> Function()? integrity,
}) {
  return storageCheckProvider.overrideWith(
    () => _StorageCheck.withDeps(scanner: scanner, integrity: integrity),
  );
}

/// The check, run each time the page opens. A failed read shows at once —
/// Riverpod's default backoff would keep the page loading (FE-STATE-11).
final AsyncNotifierProvider<_StorageCheck, _CheckView> storageCheckProvider =
    AsyncNotifierProvider.autoDispose<_StorageCheck, _CheckView>(
      _StorageCheck.new,
      retry: (int _, Object _) => null,
    );

typedef _CheckView = ({
  List<IntegrityFinding> findings,
  Project? project,
  OrphanReport? report,
  Failure? filesFailure,
});

class _StorageCheck extends AsyncNotifier<_CheckView> {
  _StorageCheck() : _scanner = null, _integrity = null;

  _StorageCheck.withDeps({this._scanner, this._integrity});

  final OrphanScanner? _scanner;
  final Future<Result<List<IntegrityFinding>>> Function()? _integrity;

  @override
  Future<_CheckView> build() async {
    final Project? project = ref.watch(currentProjectDetailsProvider);
    final Future<Result<List<IntegrityFinding>>> Function() integrity =
        _integrity ?? ref.read(integrityCheckProvider);
    final Result<List<IntegrityFinding>> checked = await integrity();
    final List<IntegrityFinding> findings = switch (checked) {
      Success<List<IntegrityFinding>>(:final List<IntegrityFinding> value) =>
        value,
      FailureResult<List<IntegrityFinding>>(:final Failure failure) =>
        throw failure,
    };
    if (project == null) {
      return (
        findings: findings,
        project: null,
        report: null,
        filesFailure: null,
      );
    }
    final OrphanScanner? scanner = _openScanner();
    if (scanner == null) {
      return (
        findings: findings,
        project: project,
        report: null,
        filesFailure: _noScanner,
      );
    }
    final Result<OrphanReport> scanned = await scanner.scan(project.id);
    return switch (scanned) {
      Success<OrphanReport>(:final OrphanReport value) => (
        findings: findings,
        project: project,
        report: value,
        filesFailure: null,
      ),
      FailureResult<OrphanReport>(:final Failure failure) => (
        findings: findings,
        project: project,
        report: null,
        filesFailure: failure,
      ),
    };
  }

  /// Marks [row]'s file as missing once the operator confirms. The row and
  /// its other evidence stay; the record's history notes the gap.
  Future<void> flagMissing(BuildContext context, MissingFile row) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.storageCheckFlagTitle,
      message: localCopy.storageCheckFlagMessage,
      confirmLabel: localCopy.storageCheckFlagConfirm,
    );
    if (!confirmed) {
      return;
    }
    final Result<void> flagged =
        await _openScanner()?.flagMissing(row) ??
        FailureResult<void>(_noScanner);
    if (!ref.mounted) {
      return;
    }
    switch (flagged) {
      case FailureResult<void>(:final Failure failure):
        if (context.mounted) {
          showAppSnack(
            context,
            Copy.of(context).failureMessage(failure),
            tone: SnackTone.error,
          );
        }
      case Success<void>():
        _drop(missing: row);
        if (context.mounted) {
          showAppSnack(context, localCopy.storageCheckFlagged);
        }
    }
  }

  /// Attaches the stray [file] to [recordId] through the normal media path,
  /// so it gains a hash and merge columns. The file stays where it is.
  Future<void> attach(
    BuildContext context,
    OrphanFile file, {
    required String recordId,
  }) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<void> adopted =
        await _openScanner()?.adopt(file, recordId: recordId) ??
        FailureResult<void>(_noScanner);
    if (!ref.mounted) {
      return;
    }
    switch (adopted) {
      case FailureResult<void>(:final Failure failure):
        if (context.mounted) {
          showAppSnack(
            context,
            Copy.of(context).failureMessage(failure),
            tone: SnackTone.error,
          );
        }
      case Success<void>():
        _drop(stray: file);
        if (context.mounted) {
          showAppSnack(context, localCopy.storageCheckAttached);
        }
    }
  }

  /// Takes a handled entry out of the report on screen.
  void _drop({MissingFile? missing, OrphanFile? stray}) {
    final _CheckView? current = state.asData?.value;
    final OrphanReport? report = current?.report;
    if (current == null || report == null) {
      return;
    }
    final List<OrphanFile> files = <OrphanFile>[
      for (final OrphanFile file in report.filesWithoutRows)
        if (!identical(file, stray)) file,
    ];
    state = AsyncData<_CheckView>((
      findings: current.findings,
      project: current.project,
      report: OrphanReport(
        filesWithoutRows: files,
        rowsWithoutFiles: <MissingFile>[
          for (final MissingFile row in report.rowsWithoutFiles)
            if (!identical(row, missing)) row,
        ],
        reclaimableBytes: files.fold<int>(
          0,
          (int total, OrphanFile file) => total + file.bytes,
        ),
      ),
      filesFailure: current.filesFailure,
    ));
  }

  /// The injected scanner, else the app's, stamped with the profile's device
  /// id; null where the app keeps no database.
  OrphanScanner? _openScanner() => _scanner ?? ref.read(orphanScannerProvider);
}

/// No scanner on this device: the file check cannot run here.
final StorageFailure _noScanner = StorageFailure(
  message: Copy.storageCheckFilesUnavailable,
  localizedMessage: Copy.messages.storageCheckFilesUnavailable,
  recoveryAction: Copy.storageCheckFilesUnavailableAction,
  localizedRecovery: Copy.messages.storageCheckFilesUnavailableAction,
);

/// The open project's records, newest first, to attach a stray file to.
final _attachableRecordsProvider = StreamProvider.autoDispose
    .family<List<RecordSummary>, String>((Ref ref, String projectId) {
      return ref
          .watch(recordRepositoryProvider)
          .watchPage(
            projectId,
            filter: const RecordFilter(),
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: AppConstants.lists.pageSize,
          );
    });

/// The sheet's list of records; a tap closes it with the record's id.
class _RecordChoice extends ConsumerWidget {
  const _RecordChoice({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView<List<RecordSummary>>(
      value: ref.watch(_attachableRecordsProvider(projectId)),
      onRetry: () => ref.invalidate(_attachableRecordsProvider(projectId)),
      isEmpty: (List<RecordSummary> records) => records.isEmpty,
      empty: () => AppEmptyState(
        icon: AppIcons.records,
        headline: Copy.of(context).storageCheckNoRecords,
        message: Copy.of(context).storageCheckNoRecordsMessage,
        actionLabel: Copy.of(context).close,
        onAction: () => Navigator.of(context).pop(),
      ),
      data: (List<RecordSummary> records) {
        final LocalizedCopy localCopy = Copy.of(context);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final RecordSummary record in records)
              AppListTile(
                key: ValueKey<String>('storage-check-record-${record.id}'),
                title: record.name.trim().isNotEmpty
                    ? record.name
                    : localCopy.recordsUntitled(record.number),
                subtitle: localCopy.recordsRowSubtitle(
                  number: record.number,
                  identifier: record.identifier,
                  context: record.contextLabel,
                ),
                onTap: () => Navigator.of(context).pop(record.id),
              ),
          ],
        );
      },
    );
  }
}
