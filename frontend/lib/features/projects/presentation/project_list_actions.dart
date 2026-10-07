import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/features/merge/merge.dart' show startPackageImport;

import 'project_list_criteria_controller.dart';

/// Shared project-list commands for the title bar and the expanded pane.
abstract final class ProjectListActions {
  /// Create control in the pane header and the title bar.
  static const ValueKey<String> createKey = ValueKey<String>(
    'project-list-create',
  );

  /// Import, in the more menu.
  static const ValueKey<String> importKey = ValueKey<String>('project-import');

  /// Opens the create form. Matches [AppRoutes.projectCreate].
  static void create(BuildContext context) {
    context.go(RoutePaths.projectCreate);
  }

  /// The list's import command and explicit archive visibility toggle.
  static List<AppOverflowAction> overflow(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool archived = ref.watch(projectListCriteriaProvider).showArchived;
    return <AppOverflowAction>[
      AppOverflowAction(
        key: importKey,
        label: localCopy.projectsImport,
        icon: AppIcons.import,
        onTap: () => unawaited(startPackageImport(context, ref)),
      ),
      AppOverflowAction(
        label: localCopy.projectShowArchived,
        icon: archived ? AppIcons.check : AppIcons.archive,
        onTap: () => ref
            .read(projectListCriteriaProvider.notifier)
            .setShowArchived(!archived),
      ),
    ];
  }

  /// Create in the expanded pane, while list-level commands stay in the
  /// shared title bar at every size.
  static Widget paneToolbar(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppButton(
        key: createKey,
        label: localCopy.projectsCreate,
        onPressed: () => create(context),
      ),
    );
  }
}
