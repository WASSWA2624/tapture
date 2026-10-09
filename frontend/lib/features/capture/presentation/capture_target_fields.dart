import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/capture_template_choice.dart';
import 'capture_controller.dart';
import 'capture_template_providers.dart';

export 'capture_template_providers.dart' show captureProjectTemplatesProvider;

/// Target recovery in the Capture body; ordinary choices live in overflow.
final class CaptureTargetFields extends ConsumerWidget {
  /// Creates recovery for the effective project and its templates.
  const CaptureTargetFields({
    required this.selectedProjectId,
    required this.templateState,
    required this.onChooseProject,
    super.key,
  });

  /// Empty when Capture has no selected project.
  final String selectedProjectId;

  /// Project-bound templates, including loading and failure.
  final AsyncValue<List<TemplateDef>> templateState;

  /// Opens the same project picker as the overflow command.
  final VoidCallback onChooseProject;

  /// Opens active project choices from the current provider snapshot.
  static Future<void> chooseProject({
    required BuildContext context,
    required WidgetRef ref,
    required String selectedProjectId,
    required bool Function() isCurrent,
    required ValueChanged<String> onChanged,
  }) async {
    final BuildContext modalContext = Navigator.of(
      context,
      rootNavigator: true,
    ).context;
    try {
      final List<ProjectListRow> rows = await ref.read(
        projectListProvider.future,
      );
      if (!context.mounted || !modalContext.mounted || !isCurrent()) return;
      await showAppChoiceSheet<String>(
        modalContext,
        label: Copy.of(context).captureProjectLabel,
        options: <Choice<String>>[
          for (final ProjectListRow row in rows)
            if (row.project.status == ProjectStatus.active)
              Choice<String>(row.project.id, row.project.name),
        ],
        value: selectedProjectId,
        onChanged: (String id) {
          if (context.mounted && isCurrent()) onChanged(id);
        },
      );
    } on Object catch (error) {
      if (context.mounted && isCurrent()) {
        final Failure failure = Failure.from(error);
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      }
    }
  }

  /// Opens current templates; a late result never changes another project.
  static Future<void> chooseTemplate({
    required BuildContext context,
    required WidgetRef ref,
    required String projectId,
    required String? templateId,
    required bool Function() isCurrent,
  }) async {
    final List<TemplateDef> templates = CaptureTemplateChoice.ordered(
      ref.read(captureProjectTemplatesProvider(projectId)).asData?.value ??
          const <TemplateDef>[],
      recentIds:
          ref.read(captureRecentTemplatesProvider(projectId)).asData?.value ??
          const <String>[],
    );
    if (templates.isEmpty || !isCurrent()) return;
    await showAppChoiceSheet<String>(
      Navigator.of(context, rootNavigator: true).context,
      label: Copy.of(context).capturePickTemplate,
      options: <Choice<String>>[
        for (final TemplateDef template in templates)
          Choice<String>(template.id, template.name),
      ],
      value: templateId,
      onChanged: (String id) {
        if (!context.mounted || !isCurrent()) return;
        final List<TemplateDef>? current = ref
            .read(captureProjectTemplatesProvider(projectId))
            .asData
            ?.value;
        if (current?.any((TemplateDef template) => template.id == id) ??
            false) {
          ref.read(projectTemplateSelectionProvider.notifier).select(id);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy copy = Copy.of(context);
    if (selectedProjectId.isEmpty) {
      return AsyncValueView<List<ProjectListRow>>(
        value: ref.watch(projectListProvider),
        onRetry: () => ref.invalidate(projectListProvider),
        data: (List<ProjectListRow> rows) {
          final bool canChoose = rows.any(
            (ProjectListRow row) => row.project.status == ProjectStatus.active,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppEmptyState(
                key: const ValueKey<String>('capture-no-project'),
                icon: AppIcons.project,
                headline: canChoose
                    ? copy.captureChooseProject
                    : copy.captureCreateProjectFirst,
                message: copy.captureNoProjectMessage,
                actionLabel: canChoose
                    ? copy.captureChooseProject
                    : copy.projectCreateTitle,
                onAction: canChoose
                    ? onChooseProject
                    : () => unawaited(context.push(RoutePaths.projectCreate)),
              ),
              if (canChoose)
                AppButton(
                  label: copy.projectCreateTitle,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      unawaited(context.push(RoutePaths.projectCreate)),
                ),
            ],
          );
        },
      );
    }
    return AsyncValueView<List<TemplateDef>>(
      value: templateState,
      isEmpty: (List<TemplateDef> templates) => templates.isEmpty,
      onRetry: () =>
          ref.invalidate(captureProjectTemplatesProvider(selectedProjectId)),
      data: (_) => const SizedBox.shrink(),
      empty: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppBanner(
            key: const ValueKey<String>('capture-no-templates'),
            message: copy.captureNoTemplates,
            icon: AppIcons.template,
            tone: SnackTone.info,
          ),
          const SizedBox(height: Space.x2),
          AppButton(
            label: copy.templatesAddChoices,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => unawaited(
              context.push(RoutePaths.projectTemplates(selectedProjectId)),
            ),
          ),
        ],
      ),
    );
  }
}
