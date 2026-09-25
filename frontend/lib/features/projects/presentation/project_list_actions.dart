import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart'
    show AppOverflowAction;

import 'project_list_filter.dart';

/// Shared list-level commands the pane header and the compact/medium
/// title bar both read, so the two layouts cannot drift.
abstract final class ProjectListActions {
  /// Create control in the pane header and the title bar.
  static const ValueKey<String> createKey = ValueKey<String>(
    'project-list-create',
  );

  /// More menu holding Show archived.
  static const ValueKey<String> overflowKey = ValueKey<String>(
    'project-list-overflow',
  );

  /// Opens the create form. Matches [AppRoutes.projectCreate].
  static void create(BuildContext context) {
    context.go(_createLocation);
  }

  /// Icon-only create for [AppPage.actions]. Empty: the footer or pane
  /// holds the one create control (FE-SIMP-01).
  static List<Widget> barActions(BuildContext _) {
    return const <Widget>[];
  }

  /// Labelled Show archived row. The check marks when the filter is on.
  static List<AppOverflowAction> overflow(WidgetRef ref) {
    final bool show = ref.watch(projectListShowArchivedProvider);
    return <AppOverflowAction>[
      AppOverflowAction(
        key: const ValueKey<String>('project-show-archived'),
        label: Copy.projectShowArchived,
        icon: show ? Icons.check : Icons.inventory_2_outlined,
        onTap: () {
          ref.read(projectListShowArchivedProvider.notifier).set(!show);
        },
      ),
    ];
  }

  /// Filled create control for the expanded pane header. Show archived
  /// stays on the Projects title, not in this pane.
  static Widget paneToolbar(
    BuildContext context,
    WidgetRef ref, {
    bool showCreate = true,
  }) {
    return Wrap(
      spacing: Space.x2,
      runSpacing: Space.x2,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        if (showCreate)
          AppButton(
            key: createKey,
            label: Copy.projectsCreate,
            onPressed: () => create(context),
          ),
      ],
    );
  }
}

/// Must match [AppRoutes.projectCreate]. This file cannot import
/// `router.dart` — the router imports the list screen.
const String _projectsRoot = '/projects';
const String _newSegment = 'new';
const String _createLocation = '$_projectsRoot/$_newSegment';
