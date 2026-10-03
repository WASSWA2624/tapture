import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

/// Templates owned by one project. Empty until that project has a template.
final captureProjectTemplatesProvider =
    StreamProvider.family<List<TemplateDef>, String>((
      Ref ref,
      String projectId,
    ) {
      if (projectId.isEmpty) {
        return Stream<List<TemplateDef>>.value(const <TemplateDef>[]);
      }
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    });

/// What a capture is filed under: the project, then the template. Both are
/// fields that open a searchable list, so they read as switches even with
/// one option (task 067 replaced the one-template rule of task 012).
///
/// Only the project is needed to capture (STANDARD rule 3): with none chosen
/// an empty state offers to create one, and a project with no template
/// captures anyway while offering to add templates.
final class CaptureTargetFields extends ConsumerWidget {
  /// Creates the fields for [selectedProjectId] and [templateId].
  const CaptureTargetFields({
    required this.selectedProjectId,
    required this.templates,
    required this.templatesLoaded,
    required this.templateId,
    required this.onProjectSelected,
    super.key,
  });

  /// The project capture files under. Empty when none is chosen.
  final String selectedProjectId;

  /// Templates of [selectedProjectId], in the order the field offers them.
  final List<TemplateDef> templates;

  /// Whether [templates] has loaded, so an empty list means there are none.
  final bool templatesLoaded;

  /// The template in use, or null while none is chosen.
  final String? templateId;

  /// Called with a newly chosen project.
  final ValueChanged<String> onProjectSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<List<ProjectListRow>> list = ref.watch(
      projectListProvider,
    );
    final List<Choice<String>> projects = list.maybeWhen(
      data: (List<ProjectListRow> rows) => <Choice<String>>[
        for (final ProjectListRow row in rows)
          if (row.project.status == ProjectStatus.active)
            Choice<String>(row.project.id, row.project.name),
      ],
      orElse: () => const <Choice<String>>[],
    );
    final bool selectedListed = projects.any(
      (Choice<String> option) => option.value == selectedProjectId,
    );
    final Widget? project = projects.isEmpty
        ? null
        : AppChoiceField<String>(
            key: const ValueKey<String>('capture-project-field'),
            label: localCopy.captureProjectLabel,
            options: projects,
            alwaysSheet: true,
            value: selectedListed ? selectedProjectId : null,
            onChanged: (String? id) {
              if (id != null && id.isNotEmpty) {
                onProjectSelected(id);
              }
            },
          );
    final Widget? template = templates.isEmpty
        ? null
        : AppChoiceField<String>(
            key: const ValueKey<String>('capture-template-field'),
            label: localCopy.capturePickTemplate,
            options: <Choice<String>>[
              for (final TemplateDef template in templates)
                Choice<String>(template.id, template.name),
            ],
            alwaysSheet: true,
            value: templateId,
            onChanged: (String? id) {
              if (id != null && id.isNotEmpty) {
                ref.read(projectTemplateSelectionProvider.notifier).select(id);
              }
            },
          );
    final bool noProject = selectedProjectId.isEmpty && list.hasValue;
    final bool noTemplates =
        selectedProjectId.isNotEmpty && templatesLoaded && templates.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Side by side from medium width up; one field alone stays full
        // width (FBK0000004).
        if (project != null && template != null)
          ResponsivePair(start: project, end: template)
        else
          ?(project ?? template),
        if (noProject) ...<Widget>[
          if (project != null) const SizedBox(height: Space.x4),
          AppEmptyState(
            key: const ValueKey<String>('capture-no-project'),
            icon: AppIcons.project,
            headline: projects.isEmpty
                ? localCopy.captureCreateProjectFirst
                : localCopy.captureChooseProject,
            message: localCopy.captureNoProjectMessage,
            actionLabel: localCopy.projectCreateTitle,
            onAction: () => context.push(RoutePaths.projectCreate),
          ),
        ],
        if (noTemplates) ...<Widget>[
          if (project != null) const SizedBox(height: Space.x2),
          AppBanner(
            key: const ValueKey<String>('capture-no-templates'),
            message: localCopy.captureNoTemplates,
            icon: AppIcons.template,
            tone: SnackTone.info,
          ),
          const SizedBox(height: Space.x2),
          AppButton(
            label: localCopy.templatesAddChoices,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () =>
                context.push(RoutePaths.projectTemplates(selectedProjectId)),
          ),
        ],
      ],
    );
  }
}
