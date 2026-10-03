import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/projects/projects.dart'
    show openProjectIdProvider;

/// The specification's Data section (§57), labelled Files: project export
/// and import, upload destinations, past uploads and merging. Each row
/// opens the screen that already does the work.
class FilesSettingsScreen extends ConsumerWidget {
  /// Creates the Files screen.
  const FilesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? projectId = ref.watch(openProjectIdProvider);
    return AppPage(
      title: localCopy.settingsFilesTitle,
      inset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (projectId == null)
            AppBanner(
              key: const ValueKey<String>('files-no-project'),
              message: localCopy.settingsFilesNoProject,
              icon: AppIcons.info,
              tone: SnackTone.info,
            )
          else ...<Widget>[
            _row(
              context,
              title: localCopy.projectExportTitle,
              subtitle: localCopy.settingsFilesExportSubtitle,
              route: RoutePaths.projectExports(projectId),
            ),
            _row(
              context,
              title: localCopy.mergePackage,
              subtitle: localCopy.settingsFilesMergeSubtitle,
              route: RoutePaths.projectMerge(projectId),
            ),
          ],
          _row(
            context,
            title: localCopy.importTitle,
            subtitle: localCopy.settingsFilesImportSubtitle,
            route: RoutePaths.projectImport,
          ),
          _row(
            context,
            title: localCopy.destinationTitle,
            subtitle: localCopy.cloudDestinationsSubtitle,
            route: RoutePaths.settingsDestinations,
          ),
          _row(
            context,
            title: localCopy.uploadHistoryTitle,
            subtitle: localCopy.settingsFilesUploadsSubtitle,
            route: RoutePaths.settingsUploads,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String route,
  }) {
    return AppListTile(
      key: ValueKey<String>('files-$route'),
      title: title,
      subtitle: subtitle,
      trailing: const Icon(AppIcons.open),
      onTap: () => context.go(route),
    );
  }
}
