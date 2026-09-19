import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;

/// Archives or unarchives a project. Records, files and settings stay put.
class ProjectArchiveAction extends ConsumerWidget {
  /// Creates the action for [project].
  const ProjectArchiveAction({super.key, required this.project});

  /// Project whose listing status is toggled.
  final Project project;

  /// Writes [ProjectStatus.archived] or restores [ProjectStatus.active].
  static Future<void> apply(WidgetRef ref, Project project) async {
    final ProjectStatus next = project.status == ProjectStatus.archived
        ? ProjectStatus.active
        : ProjectStatus.archived;
    await ref.read(projectRepositoryProvider).setStatus(project.id, next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool archived = project.status == ProjectStatus.archived;
    return AppButton(
      label: archived ? Copy.projectUnarchive : Copy.projectArchive,
      variant: AppButtonVariant.secondary,
      onPressed: () => apply(ref, project),
    );
  }
}
