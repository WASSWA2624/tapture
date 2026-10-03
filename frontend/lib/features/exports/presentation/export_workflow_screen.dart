import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';

import '../exports.dart';
import 'export_progress.dart';
import 'export_request_controls.dart';
import 'export_share_action.dart';
import 'export_workflow.dart';
import 'export_workflow_controller.dart';
import 'export_workflow_history.dart';

/// Production export route backed by durable options, writers and history.
final class ExportWorkflowScreen extends ConsumerWidget {
  const ExportWorkflowScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<ExportWorkflow> value = ref.watch(
      exportWorkflowControllerProvider(projectId),
    );
    final ExportWorkflow? workflow = value.value;
    final ExportWorkflowController controller = ref.read(
      exportWorkflowControllerProvider(projectId).notifier,
    );
    final AsyncValue<int> count = workflow == null
        ? const AsyncLoading<int>()
        : ref.watch(_countProvider(workflow.request));
    return AppPage(
      key: const ValueKey<String>('route-export'),
      title: localCopy.exportTitle,
      footer: workflow == null || workflow.running
          ? null
          : AppButton(
              key: const ValueKey<String>('export-run'),
              label: localCopy.exportRun,
              expand: true,
              onPressed: count.value == 0 || workflow.request.formats.isEmpty
                  ? null
                  : () => unawaited(
                      controller.run(
                        decide: (PreparedDeliverable prepared) =>
                            _gate(context, prepared),
                      ),
                    ),
            ),
      body: AsyncValueView<ExportWorkflow>(
        value: value,
        onRetry: () =>
            ref.invalidate(exportWorkflowControllerProvider(projectId)),
        data: (ExportWorkflow loaded) => loaded.running
            ? ExportProgress(
                stages: _stages(
                  loaded.progress,
                  localizedCopy: Copy.of(context),
                ),
                onCancel: controller.cancel,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (loaded.saved
                      case final DeliverableEntry saved) ...<Widget>[
                    ExportShareAction(
                      path: saved.path,
                      onShare: (_) =>
                          unawaited(shareDeliverable(context, ref, saved)),
                    ),
                    ExportPrivacySummaryView(
                      exportId: saved.id,
                      package: saved.package,
                    ),
                  ],
                  AsyncValueView<int>(
                    value: count,
                    onRetry: () =>
                        ref.invalidate(_countProvider(loaded.request)),
                    data: (int total) => ExportRequestControls(
                      projectId: projectId,
                      workflow: loaded,
                      count: total,
                    ),
                  ),
                  const SizedBox(height: Space.x4),
                  AppSectionHeader(title: Copy.of(context).exportHistoryTitle),
                  ExportWorkflowHistory(
                    projectId: projectId,
                    recordCount: count.value,
                  ),
                ],
              ),
      ),
    );
  }

  Future<ExportGateChoice?> _gate(
    BuildContext context,
    PreparedDeliverable prepared,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final ExportValidationReport report = prepared.validation;
    final int issues = <String>{
      ...report.incomplete,
      ...report.unapproved,
      ...report.blocked,
    }.length;
    final ExportGateChoice? choice = await showAppSheet<ExportGateChoice>(
      context,
      title: localCopy.exportGateTitle(issues),
      contentSized: true,
      builder: (BuildContext sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            Copy.of(sheet).exportGateMessage(
              incomplete: report.incomplete.length,
              unapproved: report.unapproved.length,
              blocked: report.blocked.length,
            ),
          ),
          for (final (ExportGateChoice, String) action
              in <(ExportGateChoice, String)>[
                (ExportGateChoice.fixNow, Copy.of(sheet).exportFixNow),
                (ExportGateChoice.excludeThem, Copy.of(sheet).exportExclude),
                (ExportGateChoice.exportAnyway, Copy.of(sheet).exportAnyway),
              ])
            AppButton(
              label: action.$2,
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(sheet).pop(action.$1),
            ),
        ],
      ),
    );
    if (choice == ExportGateChoice.fixNow && context.mounted) {
      context.go(RoutePaths.projectRecords(projectId));
    }
    return choice;
  }
}

final _countProvider = StreamProvider.autoDispose.family<int, ExportRequest>((
  Ref ref,
  ExportRequest request,
) {
  final DeliverableRepository? store = ref.watch(deliverableRepositoryProvider);
  return store?.watchCount(request) ?? Stream<int>.error(_unavailable);
}, retry: (int _, Object _) => null);

List<ExportStage> _stages(
  Map<String, double> progress, {
  LocalizedCopy? localizedCopy,
}) => <ExportStage>[
  for (final (String, String) stage in <(String, String)>[
    ('records', (localizedCopy ?? Copy.english).exportStageRecords),
    ('photos', (localizedCopy ?? Copy.english).exportStagePhotos),
    ('reports', (localizedCopy ?? Copy.english).exportStageReports),
    ('archive', (localizedCopy ?? Copy.english).exportStageArchive),
  ])
    (
      label: stage.$2,
      state: (progress[stage.$1] ?? 0) >= 1
          ? StepState.done
          : progress.containsKey(stage.$1)
          ? StepState.running
          : StepState.waiting,
    ),
];

final StorageFailure _unavailable = StorageFailure(
  localizedMessage: Copy.messages.failureProjectFilesAreUnavailableOnThisDevice,
);
