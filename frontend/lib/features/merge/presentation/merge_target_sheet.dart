import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/bundle/inspected_bundle.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/compatibility_issue.dart';
import '../domain/compatibility_report.dart';
import '../domain/compatibility_status.dart';
import '../domain/package_import_repository.dart';
import '../domain/template_compatibility.dart';
import '../domain/template_match.dart';
import '../merge.dart' show packageImportRepositoryProvider;
import 'compatibility_pill.dart';
import 'package_import_controller.dart';

/// Asks which project the open package merges into (task 076, W20). Each
/// local project shows whether the package's templates fit it; one that
/// does not lists its reasons and cannot be chosen. Returns the chosen
/// project's id, or null.
Future<String?> showMergeTargetSheet(BuildContext context) {
  return showAppSheet<String>(
    context,
    title: Copy.mergeTargetTitle,
    builder: (BuildContext _) => const _Targets(),
  );
}

/// One local project and how the package fits it.
typedef _Target = ({Project project, CompatibilityReport report});

final _targetsProvider = FutureProvider.autoDispose<List<_Target>>((
  Ref ref,
) async {
  final InspectedBundle? bundle = ref.watch(
    packageImportControllerProvider.select(
      (PackageImportView view) => view.bundle,
    ),
  );
  final PackageImportRepository? repository = ref.watch(
    packageImportRepositoryProvider,
  );
  if (bundle == null || repository == null) {
    return const <_Target>[];
  }
  final List<Project> projects = await ref
      .watch(projectRepositoryProvider)
      .watchAll()
      .first;
  final List<_Target> targets = <_Target>[];
  for (final Project project in projects) {
    final Result<Map<String, List<Map<String, Object?>>>> local =
        await repository.templatesOf(project.id);
    switch (local) {
      case FailureResult<Map<String, List<Map<String, Object?>>>>(
        :final Failure failure,
      ):
        throw failure;
      case Success<Map<String, List<Map<String, Object?>>>>(:final value):
        targets.add((
          project: project,
          report: TemplateCompatibility.check(
            incoming: bundle.tables,
            local: value,
            sameProject: project.id == bundle.manifest.projectId,
          ),
        ));
    }
  }
  targets.sort((_Target a, _Target b) {
    final int byStatus = a.report.status.index.compareTo(b.report.status.index);
    return byStatus != 0
        ? byStatus
        : a.project.name.toLowerCase().compareTo(b.project.name.toLowerCase());
  });
  return targets;
});

class _Targets extends ConsumerWidget {
  const _Targets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<_Target>> value = ref.watch(_targetsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x2),
      child: AsyncValueView<List<_Target>>(
        value: value,
        isEmpty: (List<_Target> targets) => targets.isEmpty,
        empty: () => const AppEmptyState(
          icon: AppIcons.project,
          headline: Copy.mergeTargetTitle,
          message: Copy.mergeTargetNone,
        ),
        onRetry: () => ref.invalidate(_targetsProvider),
        data: (List<_Target> targets) => ListView(
          children: <Widget>[
            for (final _Target target in targets)
              AppListTile(
                key: ValueKey<String>('merge-target-${target.project.id}'),
                title: target.project.name,
                status: compatibilityPill(target.report.status),
                subtitle: _reasons(target.report),
                onTap: target.report.canMerge
                    ? () => Navigator.of(context).pop(target.project.id)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  /// A blocked project's reasons, or a compatible one's differences.
  String? _reasons(CompatibilityReport report) {
    if (report.status == CompatibilityStatus.compatible) {
      return null;
    }
    final bool blocked = !report.canMerge;
    return <String>[
      for (final TemplateMatch match in report.templates)
        for (final ({CompatibilityIssue issue, String field}) found
            in match.issues)
          if (!blocked || found.issue.blocks)
            Copy.compatibilityIssue(found.issue.name, found.field),
    ].join('\n');
  }
}
