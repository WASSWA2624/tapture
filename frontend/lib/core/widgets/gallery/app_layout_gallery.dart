import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_action_dock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page_layout.dart';
import 'package:tapture/core/widgets/app_page_layout_scope.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

/// Catalogue compositions for every selected project layout and action state.
class AppLayoutGallery extends StatelessWidget {
  /// Creates the shared presentation gallery without feature dependencies.
  const AppLayoutGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy copy = Copy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final AppPageLayout layout in AppPageLayout.values) ...<Widget>[
          AppPageLayoutScope(
            key: ValueKey<String>('layout-gallery-${layout.name}'),
            layout: layout,
            child: AppSection(
              title: switch (layout) {
                AppPageLayout.essentials => copy.navProjects,
                AppPageLayout.sectioned => copy.galleryContainers,
                AppPageLayout.compact => copy.galleryCompact,
                AppPageLayout.thumbReach => copy.captureStart,
                AppPageLayout.readingFirst => copy.recordValuesEditTitle,
              },
              children: <Widget>[
                AppListTile(
                  title: copy.recordDetailTitle,
                  subtitle: copy.projectRecordsEmptyMessage,
                  leading: const Icon(AppIcons.records),
                  status: const AppStatusPill(status: RecordStatus.needsReview),
                  trailing: AppButton(
                    label: copy.recordEdit,
                    variant: AppButtonVariant.secondary,
                    onPressed: _noop,
                  ),
                  onTap: _noop,
                ),
                AppActionDock(
                  inset: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AppPrimaryAction(label: copy.save, onPressed: _noop),
                      const SizedBox(height: Space.x2),
                      AppPrimaryAction(label: copy.save),
                      const SizedBox(height: Space.x2),
                      AppPrimaryAction(label: copy.save, busy: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x4),
        ],
      ],
    );
  }
}

void _noop() {}
