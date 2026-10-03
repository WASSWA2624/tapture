// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/normalise/search_text.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';

/// The project-list search query. Survives a size-class change so the
/// pane can restore what was typed (FE-RESP-03).
final NotifierProvider<_ProjectListSearchQuery, String>
projectListSearchQueryProvider =
    NotifierProvider<_ProjectListSearchQuery, String>(
      _ProjectListSearchQuery.new,
      retry: (int _, Object _) => null,
    );

/// [projectListProvider] narrowed by the shared criteria in one linear pass.
final Provider<AsyncValue<List<ProjectListRow>>>
projectListFilteredProvider = Provider<AsyncValue<List<ProjectListRow>>>((
  Ref ref,
) {
  final ProjectListCriteria criteria = ref.watch(projectListCriteriaProvider);
  final String legacyQuery = ref.watch(projectListSearchQueryProvider);
  final AsyncValue<List<ProjectListRow>> list = ref.watch(projectListProvider);
  final String query = criteria.query.isEmpty ? legacyQuery : criteria.query;
  final String needle = foldSearchText(query.trim());
  return list.whenData((List<ProjectListRow> rows) {
    return <ProjectListRow>[
      for (final ProjectListRow row in rows)
        if (_matches(row.project, criteria, needle)) row,
    ];
  });
});

/// Opens the project list's filters, the one filter sheet every list uses
/// (FBK0000003): status, pinned state and the organisations [rows] name.
/// Choices apply at once; Clear filters restores the active list and keeps
/// the search text.
Future<void> showProjectListFilters(
  BuildContext context,
  WidgetRef ref,
  List<ProjectListRow> rows,
) {
  final LocalizedCopy localCopy = Copy.of(context);

  final List<String> organisations = <String>{
    for (final ProjectListRow row in rows)
      if ((row.project.organisation ?? '').trim().isNotEmpty)
        row.project.organisation!.trim(),
  }.toList()..sort();
  return showAppFilterSheet(
    context,
    title: localCopy.projectFiltersTitle,
    onClear: ref.read(projectListCriteriaProvider.notifier).clearFilters,
    facets: (BuildContext _) => _Facets(organisations: organisations),
  );
}

class _Facets extends ConsumerWidget {
  const _Facets({required this.organisations});

  final List<String> organisations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ProjectListCriteria criteria = ref.watch(projectListCriteriaProvider);
    final ProjectListCriteriaController controller = ref.read(
      projectListCriteriaProvider.notifier,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppMultiChoiceField<ProjectStatus>(
          key: const ValueKey<String>('project-status-filter'),
          label: localCopy.projectStatusFilter,
          options: <Choice<ProjectStatus>>[
            Choice<ProjectStatus>(
              ProjectStatus.active,
              localCopy.projectStatusActive,
            ),
            Choice<ProjectStatus>(
              ProjectStatus.archived,
              localCopy.projectStatusArchived,
            ),
          ],
          value: criteria.statuses,
          onChanged: (Set<ProjectStatus> value) {
            controller.set(criteria.copyWith(statuses: value));
          },
        ),
        const SizedBox(height: Space.x3),
        AppRadioGroup<ProjectPinFilter>(
          key: const ValueKey<String>('project-pin-filter'),
          label: localCopy.projectPinFilter,
          direction: Axis.vertical,
          value: criteria.pin,
          options: <Choice<ProjectPinFilter>>[
            for (final ProjectPinFilter value in ProjectPinFilter.values)
              Choice<ProjectPinFilter>(
                value,
                localCopy.projectPinFilterLabel(value.name),
              ),
          ],
          onChanged: (ProjectPinFilter next) {
            controller.set(criteria.copyWith(pin: next));
          },
        ),
        if (organisations.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x3),
          AppMultiChoiceField<String>(
            key: const ValueKey<String>('project-organisation-filter'),
            label: localCopy.projectOrganisation,
            // Organisations are project content, shown as stored
            // (FE-L10N-07).
            options: <Choice<String>>[
              for (final String organisation in organisations)
                Choice<String>(organisation, organisation),
            ],
            value: criteria.organisations,
            onChanged: (Set<String> value) {
              controller.set(criteria.copyWith(organisations: value));
            },
          ),
        ],
      ],
    );
  }
}

bool _matches(Project project, ProjectListCriteria criteria, String needle) {
  if (criteria.statuses.isNotEmpty &&
      !criteria.statuses.contains(project.status)) {
    return false;
  }
  final bool pinned = project.pinnedAt != null;
  if (criteria.pin == ProjectPinFilter.pinned && !pinned) {
    return false;
  }
  if (criteria.pin == ProjectPinFilter.unpinned && pinned) {
    return false;
  }
  final String organisation = project.organisation?.trim() ?? '';
  if (criteria.organisations.isNotEmpty &&
      !criteria.organisations.contains(organisation)) {
    return false;
  }
  if (needle.isEmpty) {
    return true;
  }
  return <String>[
    project.name,
    project.description ?? '',
    organisation,
  ].any((String value) => foldSearchText(value).contains(needle));
}

class _ProjectListSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query. The field owns debounce; this stores the last emit.
  void set(String value) {
    state = value;
    ref.read(projectListCriteriaProvider.notifier).setQuery(value);
  }
}
