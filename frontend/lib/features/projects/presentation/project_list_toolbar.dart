import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';

/// One search and filter toolbar reused by all project-list layouts.
final class ProjectListToolbar extends ConsumerWidget {
  /// Creates the toolbar.
  const ProjectListToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectListCriteria criteria = ref.watch(projectListCriteriaProvider);
    final List<ProjectListRow> rows =
        ref.watch(projectListProvider).asData?.value ??
        const <ProjectListRow>[];
    final Set<String> organisations = <String>{
      for (final ProjectListRow row in rows)
        if ((row.project.organisation ?? '').trim().isNotEmpty)
          row.project.organisation!.trim(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSearchField(
          hint: Copy.projectSearchHint,
          text: criteria.query,
          onChanged: ref.read(projectListCriteriaProvider.notifier).setQuery,
        ),
        const SizedBox(height: Space.x2),
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          children: <Widget>[
            AppButton(
              label: Copy.projectFilters(criteria.activeFilterCount),
              variant: AppButtonVariant.secondary,
              icon: Icons.filter_list,
              onPressed: () => unawaited(
                _openFilters(context, ref, criteria, organisations),
              ),
            ),
            if (criteria.isActive)
              AppButton(
                label: Copy.clear,
                variant: AppButtonVariant.text,
                onPressed: ref.read(projectListCriteriaProvider.notifier).clear,
              ),
          ],
        ),
      ],
    );
  }
}

Future<void> _openFilters(
  BuildContext context,
  WidgetRef ref,
  ProjectListCriteria criteria,
  Set<String> organisations,
) {
  return showAppSheet<void>(
    context,
    title: Copy.projectFiltersTitle,
    builder: (BuildContext sheetContext) {
      return _ProjectFilterForm(
        initial: criteria,
        organisations: organisations.toList()..sort(),
        onApply: (ProjectListCriteria value) {
          ref.read(projectListCriteriaProvider.notifier).set(value);
          Navigator.of(sheetContext).pop();
        },
      );
    },
  );
}

class _ProjectFilterForm extends StatefulWidget {
  const _ProjectFilterForm({
    required this.initial,
    required this.organisations,
    required this.onApply,
  });

  final ProjectListCriteria initial;
  final List<String> organisations;
  final ValueChanged<ProjectListCriteria> onApply;

  @override
  State<_ProjectFilterForm> createState() => _ProjectFilterFormState();
}

class _ProjectFilterFormState extends State<_ProjectFilterForm> {
  late final Set<ProjectStatus> _statuses = Set<ProjectStatus>.of(
    widget.initial.statuses,
  );
  late ProjectPinFilter _pin = widget.initial.pin;
  late final Set<String> _organisations = Set<String>.of(
    widget.initial.organisations,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Space.x3),
      children: <Widget>[
        const Text(Copy.projectStatusFilter),
        CheckboxListTile(
          value: _statuses.contains(ProjectStatus.active),
          title: const Text(Copy.projectStatusActive),
          onChanged: (bool? value) => _status(ProjectStatus.active, value),
        ),
        CheckboxListTile(
          value: _statuses.contains(ProjectStatus.archived),
          title: const Text(Copy.projectStatusArchived),
          onChanged: (bool? value) => _status(ProjectStatus.archived, value),
        ),
        const SizedBox(height: Space.x2),
        const Text(Copy.projectPinFilter),
        AppChoiceField<ProjectPinFilter>(
          label: Copy.projectPinFilter,
          value: _pin,
          options: <Choice<ProjectPinFilter>>[
            for (final ProjectPinFilter value in ProjectPinFilter.values)
              Choice<ProjectPinFilter>(
                value,
                Copy.projectPinFilterLabel(value.name),
              ),
          ],
          onChanged: (ProjectPinFilter? next) {
            if (next != null) setState(() => _pin = next);
          },
        ),
        if (widget.organisations.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x2),
          const Text(Copy.projectOrganisation),
          for (final String organisation in widget.organisations)
            CheckboxListTile(
              value: _organisations.contains(organisation),
              title: Text(organisation),
              onChanged: (bool? selected) {
                setState(() {
                  selected == true
                      ? _organisations.add(organisation)
                      : _organisations.remove(organisation);
                });
              },
            ),
        ],
        const SizedBox(height: Space.x3),
        AppButton(
          label: Copy.projectApplyFilters,
          onPressed: () {
            widget.onApply(
              widget.initial.copyWith(
                statuses: _statuses.isEmpty
                    ? const <ProjectStatus>{ProjectStatus.active}
                    : _statuses,
                pin: _pin,
                organisations: _organisations,
              ),
            );
          },
        ),
      ],
    );
  }

  void _status(ProjectStatus status, bool? selected) {
    setState(() {
      selected == true ? _statuses.add(status) : _statuses.remove(status);
    });
  }
}
