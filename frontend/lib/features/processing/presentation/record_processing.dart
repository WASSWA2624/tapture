import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/processing_job.dart';
import '../domain/template_choice_needed.dart';
import 'egress_preview_dialog.dart';
import 'processing_controller.dart';
import 'template_choice_sheet.dart';

/// Runs only this record's persisted job with the queue's consent and recovery.
Future<void> runRecordProcessing(
  BuildContext context,
  WidgetRef ref, {
  required String recordId,
  required String projectId,
}) {
  final ProviderContainer container = ProviderScope.containerOf(
    context,
    listen: false,
  );
  return ref
      .read(processingControllerProvider.notifier)
      .process(
        projectId: projectId,
        recordIds: <String>[recordId],
        chooseTemplate: (TemplateChoiceNeeded needed) =>
            chooseProcessingTemplate(context, needed),
        confirmOnline: (ProcessingJob job) =>
            confirmProcessingEgress(context, container, job),
        notify: false,
      );
}
