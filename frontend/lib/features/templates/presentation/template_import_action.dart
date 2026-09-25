import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../templates.dart';

/// Reads a versioned template JSON into the open project.
class TemplateImportAction extends ConsumerWidget {
  /// Creates the import action. [payload] is JSON text or a JSON object.
  const TemplateImportAction({super.key, this.projectId, this.payload});

  /// Owning project. Falls back to the open project.
  final String? projectId;

  /// JSON object or JSON text. Null or blank is the empty state.
  final Object? payload;

  /// Persists [draft] as a new template. Decode must already have succeeded.
  static Future<Result<TemplateDef>> apply(
    WidgetRef ref,
    TemplateDef draft,
  ) async {
    return ref.read(templateRepositoryProvider).save(draft);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? projectId =
        this.projectId ?? ref.watch(currentProjectProvider);
    final Object? payload = this.payload;
    final bool missingPayload =
        payload == null || (payload is String && payload.trim().isEmpty);
    if (missingPayload || projectId == null || projectId.isEmpty) {
      return const AppPage(
        key: ValueKey<String>('route-template-import'),
        title: Copy.templatesImport,
        body: AppEmptyState(
          icon: AppIcons.import,
          headline: Copy.templatesImportEmptyHeadline,
          message: Copy.templatesImportEmptyMessage,
        ),
      );
    }
    return switch (TemplateJson.decode(payload, projectId: projectId)) {
      FailureResult<TemplateDef>(:final Failure failure) => AppPage(
        key: const ValueKey<String>('route-template-import'),
        title: Copy.templatesImport,
        body: AppErrorState(failure: failure),
      ),
      Success<TemplateDef>(:final TemplateDef value) => AppPage(
        key: const ValueKey<String>('route-template-import'),
        title: Copy.templatesImport,
        body: AppListTile(title: value.name),
        footer: AppPrimaryAction(
          label: Copy.templatesImport,
          onPressed: () => unawaited(_save(context, ref, value)),
        ),
      ),
    };
  }
}

Future<void> _save(
  BuildContext context,
  WidgetRef ref,
  TemplateDef draft,
) async {
  final Result<TemplateDef> result = await TemplateImportAction.apply(
    ref,
    draft,
  );
  if (!context.mounted) {
    return;
  }
  switch (result) {
    case Success<TemplateDef>():
      return;
    case FailureResult<TemplateDef>(:final Failure failure):
      showAppSnack(context, failure.message, tone: SnackTone.error);
  }
}
