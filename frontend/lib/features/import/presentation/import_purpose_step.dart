import 'dart:async';

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show currentProjectProvider;

import 'import_controller.dart';
import 'import_screen.dart';

/// Spreadsheets only (task 020 step 2): are the rows records to hold, or
/// the register to verify against? Records go on to the column mapping; a
/// register becomes the reference dataset verification checks against,
/// through the dataset importer, and creates no record.
final class ImportPurposeStep extends ConsumerWidget {
  /// Creates the question for the spreadsheet the import page holds.
  const ImportPurposeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ImportView view = ref.watch(importControllerProvider);
    final PickedDocument? document = view.document;
    final Failure? failure = view.failure;
    final Widget body;
    if (view.busy) {
      body = AppProgressSteps(
        steps: <ProgressStep>[
          ProgressStep(
            label: localCopy.importCheckingFile,
            state: StepState.running,
          ),
        ],
      );
    } else if (failure != null) {
      body = AppErrorState(
        failure: failure,
        onRetry: () => context.go(RoutePaths.projectImport),
      );
    } else if (document == null) {
      body = AppEmptyState(
        icon: AppIcons.import,
        headline: localCopy.importNoSheetHeadline,
        message: localCopy.importNoSheetMessage,
        actionLabel: localCopy.importChooseFile,
        onAction: () => context.go(RoutePaths.projectImport),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppListTile(
            key: const ValueKey<String>('import-purpose-records'),
            leading: const Icon(AppIcons.records),
            title: localCopy.importPurposeRecords,
            subtitle: localCopy.importPurposeRecordsLine,
            trailing: const Icon(AppIcons.open),
            onTap: () =>
                unawaited(context.push(RoutePaths.projectImportRecords)),
          ),
          AppListTile(
            key: const ValueKey<String>('import-purpose-register'),
            leading: const Icon(AppIcons.verified),
            title: localCopy.importPurposeRegister,
            subtitle: localCopy.importPurposeRegisterLine,
            trailing: const Icon(AppIcons.open),
            onTap: () => unawaited(_register(context, ref)),
          ),
        ],
      );
    }
    return AppPage(
      key: const ValueKey<String>('route-import-purpose'),
      title: localCopy.importPurposeTitle,
      inset: false,
      body: body,
    );
  }
}

Future<void> _register(BuildContext context, WidgetRef ref) async {
  final ImportDestination? next = await ref
      .read(importControllerProvider.notifier)
      .asRegister(projectId: ref.read(currentProjectProvider));
  if (next == null || !context.mounted) {
    return;
  }
  openImportDestination(context, ref, next);
}
