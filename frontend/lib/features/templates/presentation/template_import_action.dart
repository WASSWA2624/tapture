import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../templates.dart';
import 'template_import_controller.dart';
import 'template_locations.dart';

/// Picks JSON templates or workbooks, then confirms an import into the project.
class TemplateImportAction extends ConsumerWidget {
  const TemplateImportAction({super.key, this.projectId, this.payload});

  final String? projectId;
  final Object? payload;

  static Future<Result<TemplateDef>> apply(WidgetRef ref, TemplateDef draft) =>
      ref.read(templateRepositoryProvider).save(draft);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? projectId =
        this.projectId ??
        (GoRouter.maybeOf(context) == null
            ? null
            : TemplateLocations.projectIdOf(context)) ??
        ref.watch(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      return AppPage(
        key: const ValueKey<String>('route-template-import'),
        title: localCopy.templatesImport,
        body: AppEmptyState(
          icon: AppIcons.import,
          headline: localCopy.projectsEmptyHeadline,
          message: localCopy.projectsEmptyMessage,
          actionLabel: localCopy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
      );
    }
    final input = (projectId: projectId, payload: payload);
    final AsyncValue<TemplateDef?> value = ref.watch(
      templateImportControllerProvider(input),
    );
    final TemplateImportController controller = ref.read(
      templateImportControllerProvider(input).notifier,
    );
    Future<void> choose() => _choose(context, controller);
    Future<void> save() => _save(context, controller);
    return AppPage(
      key: const ValueKey<String>('route-template-import'),
      title: localCopy.templatesImport,
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? draft) => draft == null,
        empty: () => AppEmptyState(
          icon: AppIcons.import,
          headline: Copy.of(context).templatesImportEmptyHeadline,
          message: Copy.of(context).templatesImportEmptyMessage,
          actionLabel: Copy.of(context).templatesImport,
          onAction: choose,
        ),
        onRetry: choose,
        data: (TemplateDef? draft) => AppListTile(title: draft!.name),
      ),
      footer: value.value == null
          ? null
          : AppPrimaryAction(
              label: localCopy.templatesImport,
              busy: value.isLoading,
              onPressed: save,
            ),
    );
  }
}

Future<void> _choose(
  BuildContext context,
  TemplateImportController controller,
) async {
  final PickedDocument? workbook = await controller.choose();
  if (workbook == null) return;
  if (!context.mounted) {
    await TemplateDocumentImport.discard(workbook);
    return;
  }
  context.go(
    RoutePaths.templateXlsx(projectId: TemplateLocations.projectIdOf(context)),
    extra: workbook,
  );
}

Future<void> _save(
  BuildContext context,
  TemplateImportController controller,
) async {
  final Result<TemplateDef>? result = await controller.save();
  if (!context.mounted || result == null) return;
  switch (result) {
    case Success<TemplateDef>(:final TemplateDef value):
      GoRouter.maybeOf(
        context,
      )?.go(TemplateLocations.detail(context, value.id));
    case FailureResult<TemplateDef>(:final Failure failure):
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
  }
}
