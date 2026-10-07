import 'dart:async';

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/merge/merge.dart' show startPackageImport;
import 'package:tapture/features/projects/projects.dart'
    show currentProjectProvider;

import '../domain/import_flow.dart';
import 'import_controller.dart';

/// The one entry for every file the app imports (task 020).
///
/// One action picks a file; the gate checks it, its kind is detected from
/// what the gate accepted and its own content, and the flow that owns that
/// kind opens at once: a bundle the merge flow, a dataset the dataset
/// importer, a template the template import, and a spreadsheet the purpose
/// question. Each destination is explained in one line below. A refused
/// file shows its reason here, before any flow starts.
final class ImportScreen extends ConsumerStatefulWidget {
  /// Creates the import page.
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> with StateRefresh {
  bool _showSupportedFiles = false;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ImportView view = ref.watch(importControllerProvider);
    final Failure? failure = view.failure;
    void choose() => unawaited(chooseImportFile(context, ref));
    return AppPage(
      key: const ValueKey<String>('route-import'),
      title: localCopy.importTitle,
      footer: AppPrimaryAction(
        label: localCopy.importChooseFile,
        busy: view.busy,
        onPressed: choose,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (view.busy)
            AppProgressSteps(
              key: const ValueKey<String>('import-checking'),
              steps: <ProgressStep>[
                ProgressStep(
                  label: localCopy.importCheckingFile,
                  state: StepState.running,
                ),
              ],
            )
          else if (failure != null)
            AppErrorState(failure: failure)
          else
            Text(localCopy.importEmptyMessage),
          AppSectionHeader(
            title: localCopy.importSupportedFiles,
            expanded: _showSupportedFiles,
            onToggle: () =>
                refresh(() => _showSupportedFiles = !_showSupportedFiles),
          ),
          if (_showSupportedFiles)
            for (final _Kind kind in _kinds(localCopy))
              AppListTile(
                key: ValueKey<String>('import-kind-${kind.flow.name}'),
                leading: Icon(kind.icon),
                title: kind.title,
                subtitle: kind.line,
                wrapText: true,
              ),
        ],
      ),
    );
  }
}

/// Picks a file on the import page and opens the flow its kind belongs to.
/// The page's action, and its retry after a refusal.
Future<void> chooseImportFile(BuildContext context, WidgetRef ref) async {
  final ImportDestination? next = await ref
      .read(importControllerProvider.notifier)
      .choose(projectId: ref.read(currentProjectProvider));
  if (next == null || !context.mounted) {
    return;
  }
  openImportDestination(context, ref, next);
}

/// Opens [next]: the merge flow for a bundle, else its location.
void openImportDestination(
  BuildContext context,
  WidgetRef ref,
  ImportDestination next,
) {
  final String? location = next.location;
  if (next.flow == ImportFlow.bundle || location == null) {
    unawaited(startPackageImport(context, ref, supplied: next.document));
    return;
  }
  unawaited(context.push(location, extra: next.extra));
}

typedef _Kind = ({ImportFlow flow, IconData icon, String title, String line});

List<_Kind> _kinds(LocalizedCopy copy) => <_Kind>[
  (
    flow: ImportFlow.bundle,
    icon: AppIcons.merge,
    title: copy.importKindBundle,
    line: copy.importBundleLine,
  ),
  (
    flow: ImportFlow.spreadsheet,
    icon: AppIcons.columns,
    title: copy.importKindSheet,
    line: copy.importSheetLine,
  ),
  (
    flow: ImportFlow.dataset,
    icon: AppIcons.dataset,
    title: copy.importKindDataset,
    line: copy.importDatasetLine,
  ),
  (
    flow: ImportFlow.template,
    icon: AppIcons.template,
    title: copy.importKindTemplate,
    line: copy.importTemplateLine,
  ),
];
