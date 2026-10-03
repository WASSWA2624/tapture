import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/bundle/bundle_manifest.dart';
import 'package:tapture/core/bundle/inspected_bundle.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/feedback/show_app_text_prompt.dart';

import '../domain/package_import_repository.dart';
import '../domain/package_presence.dart';
import 'merge_target_sheet.dart';
import 'package_import_controller.dart';

/// Imports the package as a new project, on the import sheet.
const ValueKey<String> importAsNewKey = ValueKey<String>('import-as-new');

/// Opens the merge target sheet, on the import sheet.
const ValueKey<String> importMergeIntoKey = ValueKey<String>(
  'import-merge-into',
);

/// Cancels the check while a package opens.
const ValueKey<String> importCancelKey = ValueKey<String>('import-cancel');

/// Brings a project package in (task 076, W19): pick it, check it with a
/// Cancel, then by its project: a project unknown here imports as new or
/// merges into one chosen here; a live one goes to its merge preview; a
/// deleted one is refused, since a merge never brings back what was
/// deleted. [intoProjectId], from a project's menu, merges into that one.
Future<void> startPackageImport(
  BuildContext context,
  WidgetRef ref, {
  String? intoProjectId,
  PickedDocument? supplied,
  Future<void> Function()? onApplied,
  bool waitForPreview = false,
}) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final PackageImportController flow = ref.read(
    packageImportControllerProvider.notifier,
  );
  final Result<PickedDocument> picked;
  if (supplied == null) {
    picked = await flow.pick();
  } else {
    await flow.finish();
    picked = Success<PickedDocument>(supplied);
  }
  flow.onApplied = onApplied;
  if (!context.mounted) {
    await flow.finish();
    await discardPickedCopy(supplied);
    return;
  }
  final PickedDocument document;
  switch (picked) {
    case FailureResult<PickedDocument>(:final Failure failure):
      if (failure is! CancelledFailure) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      }
      return;
    case Success<PickedDocument>(:final PickedDocument value):
      document = value;
  }
  final Result<bool> protected = await flow.needsPassword(document);
  if (!context.mounted) {
    await flow.finish();
    return;
  }
  if (protected case FailureResult<bool>(:final Failure failure)) {
    await flow.finish();
    if (!context.mounted) return;
    showAppSnack(
      context,
      failure.message,
      tone: SnackTone.error,
      localizedMessage: failure.explanation,
    );
    return;
  }
  String? password;
  if ((protected as Success<bool>).value) {
    password = await showAppTextPrompt(
      context,
      title: localCopy.bundlePassword,
      label: localCopy.bundlePassword,
      obscureText: true,
      validate: (String value) async => value.isEmpty
          ? FailureResult<void>(
              ValidationFailure(
                localizedMessage: Copy.messages.bundlePasswordRequired,
              ),
            )
          : const Success<void>(null),
    );
    if (password == null || !context.mounted) {
      await flow.finish();
      return;
    }
  }
  final Result<InspectedBundle> checked = await _busy(
    context,
    title: localCopy.importChecking,
    onCancel: flow.cancel,
    work: flow.check(document, password: password),
  );
  if (!context.mounted) {
    await flow.finish();
    return;
  }
  final InspectedBundle bundle;
  switch (checked) {
    case FailureResult<InspectedBundle>(:final Failure failure):
      if (failure is! CancelledFailure) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      }
      return;
    case Success<InspectedBundle>(:final InspectedBundle value):
      bundle = value;
  }
  if (intoProjectId != null) {
    final Future<Object?> preview = context.push(
      RoutePaths.projectMerge(intoProjectId),
    );
    if (waitForPreview) await preview;
    return;
  }
  final Result<PackagePresence> presence = await flow.presence();
  if (!context.mounted) {
    await flow.finish();
    return;
  }
  switch (presence) {
    case FailureResult<PackagePresence>(:final Failure failure):
      await flow.finish();
      if (context.mounted) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      }
    case Success<PackagePresence>(value: PackagePresence.deleted):
      await flow.finish();
      if (context.mounted) {
        showAppSnack(
          context,
          localCopy.importProjectDeletedHere,
          tone: SnackTone.error,
        );
      }
    case Success<PackagePresence>(value: PackagePresence.live):
      final Future<Object?> preview = context.push(
        RoutePaths.projectMerge(bundle.manifest.projectId),
      );
      if (waitForPreview) await preview;
    case Success<PackagePresence>(value: PackagePresence.absent):
      await _offer(context, ref, bundle, waitForPreview: waitForPreview);
  }
}

enum _Choice { asNew, mergeInto }

/// The import sheet: what the package holds, then import or merge.
Future<void> _offer(
  BuildContext context,
  WidgetRef ref,
  InspectedBundle bundle, {
  required bool waitForPreview,
}) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final PackageImportController flow = ref.read(
    packageImportControllerProvider.notifier,
  );
  final _Choice? choice = await showAppSheet<_Choice>(
    context,
    title: localCopy.importSheetTitle,
    contentSized: true,
    builder: (BuildContext sheet) => _ImportSheet(manifest: bundle.manifest),
  );
  if (!context.mounted) {
    await flow.finish();
    return;
  }
  switch (choice) {
    case null:
      await flow.finish();
    case _Choice.mergeInto:
      final String? target = await showMergeTargetSheet(context);
      if (!context.mounted) {
        await flow.finish();
        return;
      }
      if (target == null) {
        await flow.finish();
        return;
      }
      final Future<Object?> preview = context.push(
        RoutePaths.projectMerge(target),
      );
      if (waitForPreview) await preview;
    case _Choice.asNew:
      final Result<ImportedProject> imported = await _busy(
        context,
        title: localCopy.importCopying,
        work: flow.importAsNew(),
      );
      if (!context.mounted) {
        return;
      }
      switch (imported) {
        case FailureResult<ImportedProject>(:final Failure failure):
          await flow.finish();
          if (context.mounted) {
            showAppSnack(
              context,
              failure.message,
              tone: SnackTone.error,
              localizedMessage: failure.explanation,
            );
          }
        case Success<ImportedProject>(:final ImportedProject value):
          showAppSnack(
            context,
            localCopy.importDone(value.records),
            tone: SnackTone.success,
          );
          context.go(RoutePaths.project(value.projectId));
      }
  }
}

class _ImportSheet extends StatelessWidget {
  const _ImportSheet({required this.manifest});

  final BundleManifest manifest;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final int bytes = manifest.entries.fold<int>(
      0,
      (int total, entry) => total + entry.byteLength,
    );
    return Padding(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppListTile(
            title: manifest.projectName,
            subtitle:
                '${localCopy.importFrom(manifest.operatorName ?? manifest.sourceDeviceId, manifest.exportedAt)}\n'
                '${localCopy.importHolds(manifest.counts['records'] ?? 0, manifest.counts['photos'] ?? 0, bytes)}',
          ),
          const SizedBox(height: Space.x4),
          AppButton(
            key: importAsNewKey,
            label: localCopy.importAsNewProject,
            expand: true,
            onPressed: () => Navigator.of(context).pop(_Choice.asNew),
          ),
          const SizedBox(height: Space.x2),
          AppButton(
            key: importMergeIntoKey,
            label: localCopy.importMergeInto,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => Navigator.of(context).pop(_Choice.mergeInto),
          ),
        ],
      ),
    );
  }
}

/// Runs [work] behind a dialog that names it, shows its progress and, when
/// [onCancel] is given, offers Cancel. The dialog closes when [work] ends.
Future<T> _busy<T>(
  BuildContext context, {
  required String title,
  required Future<T> work,
  VoidCallback? onCancel,
}) async {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext _) =>
          _BusyDialog(title: title, onCancel: onCancel),
    ),
  );
  try {
    return await work;
  } finally {
    if (navigator.mounted) {
      navigator.pop();
    }
  }
}

class _BusyDialog extends ConsumerWidget {
  const _BusyDialog({required this.title, this.onCancel});

  final String title;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final double progress = ref.watch(
      packageImportControllerProvider.select(
        (PackageImportView view) => view.progress,
      ),
    );
    final VoidCallback? onCancel = this.onCancel;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title, style: AppText.title),
        content: Semantics(
          liveRegion: true,
          label: title,
          child: LinearProgressIndicator(value: progress > 0 ? progress : null),
        ),
        actions: <Widget>[
          if (onCancel != null)
            AppButton(
              key: importCancelKey,
              label: localCopy.cancel,
              variant: AppButtonVariant.text,
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}
