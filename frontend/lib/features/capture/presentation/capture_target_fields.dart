import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
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
/// one option. When capture cannot start, a line under them says why.
final class CaptureTargetFields extends ConsumerWidget {
  /// Creates the fields for [selectedProjectId] and [templateId].
  const CaptureTargetFields({
    required this.selectedProjectId,
    required this.templates,
    required this.templateId,
    required this.onProjectSelected,
    super.key,
  });

  /// The project capture files under. Empty when none is chosen.
  final String selectedProjectId;

  /// Templates of [selectedProjectId], offered by the template field.
  final List<TemplateDef> templates;

  /// The template in use, or null while the person must pick one.
  final String? templateId;

  /// Called with a newly chosen project.
  final ValueChanged<String> onProjectSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProjectListRow>> list = ref.watch(
      projectListProvider,
    );
    final List<ProjectListRow> active = list.maybeWhen(
      data: (List<ProjectListRow> rows) => <ProjectListRow>[
        for (final ProjectListRow row in rows)
          if (row.project.status == ProjectStatus.active) row,
      ],
      orElse: () => const <ProjectListRow>[],
    );
    final List<Choice<String>> projects = <Choice<String>>[];
    bool templatesSettled = list.hasValue;
    for (final ProjectListRow row in active) {
      final AsyncValue<List<TemplateDef>> owned = ref.watch(
        captureProjectTemplatesProvider(row.project.id),
      );
      if (!owned.hasValue) {
        templatesSettled = false;
      }
      final bool allowed = owned.maybeWhen(
        data: (List<TemplateDef> loaded) => loaded.isNotEmpty,
        orElse: () => false,
      );
      if (allowed) {
        projects.add(Choice<String>(row.project.id, row.project.name));
      }
    }
    final bool selectedAllowed = projects.any(
      (Choice<String> option) => option.value == selectedProjectId,
    );
    final String? message = captureGateMessage(
      projectsLoaded: list.hasValue,
      activeCount: active.length,
      hasChoice: projects.isNotEmpty,
      selectedId: selectedProjectId,
      selectedAllowed: selectedAllowed,
      templatesSettled: templatesSettled,
    );
    final Widget? project = projects.isEmpty
        ? null
        : AppChoiceField<String>(
            key: const ValueKey<String>('capture-project-field'),
            label: Copy.captureProjectLabel,
            options: projects,
            alwaysSheet: true,
            value: selectedAllowed ? selectedProjectId : null,
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
            label: Copy.capturePickTemplate,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Side by side from medium width up; one field alone stays full
        // width (FBK0000004).
        if (project != null && template != null)
          ResponsivePair(start: project, end: template)
        else
          ?(project ?? template),
        if (message != null) ...<Widget>[
          if (projects.isNotEmpty) const SizedBox(height: Space.x2),
          Text(message, style: AppText.body),
        ],
      ],
    );
  }
}

/// Why capture cannot start yet, or null when it can.
String? captureGateMessage({
  required bool projectsLoaded,
  required int activeCount,
  required bool hasChoice,
  required String selectedId,
  required bool selectedAllowed,
  required bool templatesSettled,
}) {
  if (!projectsLoaded || selectedAllowed) {
    return null;
  }
  if (activeCount == 0) {
    return Copy.captureCreateProjectFirst;
  }
  if (selectedId.isNotEmpty && templatesSettled) {
    return Copy.captureNeedsTemplate;
  }
  if (hasChoice) {
    return Copy.captureChooseProject;
  }
  if (templatesSettled) {
    return Copy.captureNeedsTemplate;
  }
  return null;
}
