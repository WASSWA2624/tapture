import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'current_project.dart';

/// Soft-deletes a project after a typed-name confirmation.
class ProjectDeleteAction extends ConsumerWidget {
  /// Creates the action for [project].
  const ProjectDeleteAction({super.key, required this.project});

  /// Project that would be hidden and moved to the recycle area.
  final Project project;

  /// Opens the destructive confirm, then deletes when the name matches.
  static Future<void> confirm(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final ProjectRepository repo = ref.read(projectRepositoryProvider);
    final Result<ProjectOwnedCounts> counted = await repo.ownedCounts(
      project.id,
    );
    if (!context.mounted) {
      return;
    }
    final ProjectOwnedCounts counts = switch (counted) {
      Success<ProjectOwnedCounts>(:final ProjectOwnedCounts value) => value,
      FailureResult<ProjectOwnedCounts>() => (records: 0, files: 0),
    };
    bool exportFirst = false;
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.projectDeleteTitle(project.name),
      message: localCopy.projectDeleteMessage(
        records: counts.records,
        files: counts.files,
        days: AppConstants.retention.days,
      ),
      confirmLabel: localCopy.projectDelete,
      destructive: true,
      typedValue: project.name,
      typedLabel: localCopy.projectDeleteTypeName,
      alternativeLabel: localCopy.projectExportFirst,
      onAlternative: () => exportFirst = true,
    );
    if (!context.mounted) {
      return;
    }
    if (exportFirst) {
      context.go(RoutePaths.projectExports(project.id));
      return;
    }
    if (!confirmed) {
      return;
    }
    await repo.delete(project.id);
    if (ref.read(currentProjectProvider) == project.id) {
      ref.read(currentProjectProvider.notifier).close();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppButton(
      label: localCopy.projectDelete,
      variant: AppButtonVariant.destructive,
      onPressed: () => confirm(context, ref, project),
    );
  }
}
