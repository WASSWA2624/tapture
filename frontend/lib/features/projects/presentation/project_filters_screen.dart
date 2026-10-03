import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';

/// Projects › Filters. Criteria apply together, then the list returns.
final class ProjectFiltersScreen extends ConsumerStatefulWidget {
  /// Creates the filters page.
  const ProjectFiltersScreen({super.key});

  @override
  ConsumerState<ProjectFiltersScreen> createState() =>
      _ProjectFiltersScreenState();
}

class _ProjectFiltersScreenState extends ConsumerState<ProjectFiltersScreen>
    with StateRefresh {
  late Set<ProjectStatus> _statuses;
  late ProjectPinFilter _pin;
  late Set<String> _organisations;

  @override
  void initState() {
    super.initState();
    final ProjectListCriteria criteria = ref.read(projectListCriteriaProvider);
    _statuses = Set<ProjectStatus>.of(criteria.statuses);
    _pin = criteria.pin;
    _organisations = Set<String>.of(criteria.organisations);
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<ProjectListRow> rows =
        ref.watch(projectListProvider).asData?.value ??
        const <ProjectListRow>[];
    final List<String> organisations = <String>[
      for (final ProjectListRow row in rows)
        if ((row.project.organisation ?? '').trim().isNotEmpty)
          row.project.organisation!.trim(),
    ]..sort();
    return AppPage(
      key: const ValueKey<String>('route-project-filters'),
      title: '${localCopy.navProjects} › ${localCopy.projectFiltersTitle}',
      footer: AppPrimaryAction(
        label: localCopy.projectApplyFilters,
        onPressed: () {
          final ProjectListCriteria current = ref.read(
            projectListCriteriaProvider,
          );
          ref
              .read(projectListCriteriaProvider.notifier)
              .set(
                current.copyWith(
                  statuses: _statuses.isEmpty
                      ? const <ProjectStatus>{ProjectStatus.active}
                      : _statuses,
                  pin: _pin,
                  organisations: _organisations,
                ),
              );
          context.pop();
        },
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSectionHeader(title: localCopy.projectStatusFilter),
          AppCheckboxGroup<ProjectStatus>(
            label: localCopy.projectStatusFilter,
            showLabel: false,
            value: _statuses,
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
            onChanged: (Set<ProjectStatus> value) {
              refresh(() => _statuses = value);
            },
          ),
          const SizedBox(height: Space.x4),
          AppSectionHeader(title: localCopy.projectPinFilter),
          AppRadioGroup<ProjectPinFilter>(
            label: localCopy.projectPinFilter,
            showLabel: false,
            direction: Axis.vertical,
            value: _pin,
            options: <Choice<ProjectPinFilter>>[
              for (final ProjectPinFilter value in ProjectPinFilter.values)
                Choice<ProjectPinFilter>(
                  value,
                  localCopy.projectPinFilterLabel(value.name),
                ),
            ],
            onChanged: (ProjectPinFilter next) {
              refresh(() => _pin = next);
            },
          ),
          const SizedBox(height: Space.x4),
          AppSectionHeader(title: localCopy.projectOrganisation),
          if (organisations.isNotEmpty)
            AppCheckboxGroup<String>(
              label: localCopy.projectOrganisation,
              showLabel: false,
              value: _organisations,
              options: <Choice<String>>[
                for (final String organisation in organisations)
                  Choice<String>(organisation, organisation),
              ],
              onChanged: (Set<String> value) {
                refresh(() => _organisations = value);
              },
            ),
        ],
      ),
    );
  }
}
