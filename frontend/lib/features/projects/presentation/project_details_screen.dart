import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';

/// The project's details to read, with Edit details as the way to change
/// them (FBK0000156). Create, update and delete each have their own flow;
/// this is the read page the menu's "Project details" opens (D8).
final class ProjectDetailsScreen extends ConsumerWidget {
  /// Creates the page for [projectId]. An archived project shows too.
  const ProjectDetailsScreen({required this.projectId, super.key});

  /// Project shown.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<Project?> value = ref.watch(
      projectByIdProvider(projectId),
    );
    final bool loaded = value.asData?.value != null;
    return AppPage(
      key: const ValueKey<String>('route-project-details'),
      title: localCopy.projectEditTitle,
      footer: loaded
          ? AppPrimaryAction(
              key: const ValueKey<String>('project-details-edit'),
              label: localCopy.projectEditDetails,
              onPressed: () =>
                  unawaited(context.push(RoutePaths.projectEdit(projectId))),
            )
          : null,
      body: AsyncValueView<Project?>(
        value: value,
        isEmpty: (Project? project) => project == null,
        empty: () => AppEmptyState(
          icon: AppIcons.project,
          headline: Copy.of(context).projectEditEmptyHeadline,
          message: Copy.of(context).projectEditEmptyMessage,
        ),
        onRetry: () => ref.invalidate(projectByIdProvider(projectId)),
        data: (Project? project) => _ProjectDetails(project: project!),
      ),
    );
  }
}

class _ProjectDetails extends StatelessWidget {
  const _ProjectDetails({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String locale = Localizations.localeOf(context).toString();
    String day(DateTime? value) => value == null
        ? Copy.of(context).projectValueNotSet
        : DateFormat.yMMMd(locale).format(value.toLocal());
    String text(String? value) => value == null || value.trim().isEmpty
        ? Copy.of(context).projectValueNotSet
        : value;
    final ProjectCoverPhoto? cover = project.settings.coverPhoto;
    final double edge = AppConstants.images.thumbnailEdge.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The browser stores no project photo (task 066, D7).
        if (cover != null && !kIsWeb) ...<Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: RecordThumb(
              key: const ValueKey<String>('project-details-photo'),
              sha256: cover.sha256,
              storagePath: cover.path,
              size: edge,
            ),
          ),
          const SizedBox(height: Space.x3),
        ],
        _row(localCopy.projectName, project.name),
        _row(localCopy.projectDescription, text(project.description)),
        _row(localCopy.projectOrganisation, text(project.organisation)),
        _row(localCopy.projectStartsOn, day(project.startsOn)),
        _row(localCopy.projectEndsOn, day(project.endsOn)),
        _row(
          localCopy.projectStatus,
          project.status == ProjectStatus.archived
              ? localCopy.projectStatusArchived
              : localCopy.projectStatusActive,
        ),
        _row(localCopy.projectCreatedAt, day(project.createdAt)),
        _row(localCopy.projectUpdatedAt, day(project.updatedAt)),
      ],
    );
  }

  Widget _row(String label, String value) {
    return AppListTile(title: label, subtitle: value, dense: true);
  }
}
