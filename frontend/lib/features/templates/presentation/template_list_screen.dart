import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/template_def.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'template_duplicate_action.dart';
import 'template_locations.dart';

/// A project's templates, each row showing field and record counts.
class TemplateListScreen extends ConsumerWidget {
  /// Creates the list. [projectId] keeps navigation inside that project.
  const TemplateListScreen({this.projectId, super.key});

  /// Project that opened this list, when the route is project-scoped.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TemplateDef>> value = ref.watch(templateListProvider);
    final Map<String, int> recordCounts = ref.watch(
      templateRecordCountsProvider,
    );
    return AppPage(
      key: const ValueKey<String>('route-templates'),
      title: Copy.navTemplates,
      showAppBar: false,
      inset: false,
      scrollable: false,
      footer: value.hasValue
          ? AppPrimaryAction(
              label: Copy.templatesCreate,
              onPressed: () => context.go(
                TemplateLocations.create(context, projectId: projectId),
              ),
            )
          : null,
      body: AsyncValueView<List<TemplateDef>>(
        value: value,
        isEmpty: (List<TemplateDef> rows) => rows.isEmpty,
        empty: () => _empty(context),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (List<TemplateDef> rows) {
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                for (final TemplateDef template in rows)
                  AppListTile(
                    title: template.name,
                    subtitle: Copy.templateListSubtitle(
                      fields: template.fields.length,
                      records: recordCounts[template.id] ?? 0,
                    ),
                    trailing: AppOverflowMenu(
                      items: _actions(
                        context,
                        ref,
                        template,
                        recordCounts[template.id] ?? 0,
                      ),
                    ),
                    onTap: () => _open(context, template.id),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<AppOverflowAction> _actions(
    BuildContext context,
    WidgetRef ref,
    TemplateDef template,
    int recordCount,
  ) {
    return <AppOverflowAction>[
      AppOverflowAction(
        label: Copy.templatesOpen,
        icon: Icons.article_outlined,
        onTap: () => _open(context, template.id),
      ),
      AppOverflowAction(
        label: Copy.projectsDuplicate,
        icon: Icons.copy_outlined,
        onTap: () => unawaited(_duplicate(context, ref, template)),
      ),
      AppOverflowAction(
        label: Copy.templatesExport,
        icon: Icons.ios_share_outlined,
        onTap: () =>
            context.go(TemplateLocations.child(context, template.id, 'export')),
      ),
      AppOverflowAction(
        label: Copy.templatesImport,
        icon: Icons.file_upload_outlined,
        onTap: () => context.go(TemplateLocations.import(context)),
      ),
      if (recordCount == 0)
        AppOverflowAction(
          label: Copy.templatesDelete,
          icon: Icons.delete_outline,
          onTap: () => unawaited(_delete(context, ref, template, recordCount)),
        ),
    ];
  }
}

Widget _empty(BuildContext context) {
  return AppEmptyState(
    icon: Icons.article_outlined,
    headline: Copy.templatesEmptyHeadline,
    message: Copy.templatesEmptyMessage,
    actionLabel: Copy.templatesPickLibrary,
    onAction: () => context.go(TemplateLocations.library(context)),
  );
}

Future<void> _duplicate(
  BuildContext context,
  WidgetRef ref,
  TemplateDef template,
) async {
  final TemplateDef? copy = await TemplateDuplicateAction.apply(ref, template);
  if (copy == null || !context.mounted) {
    return;
  }
  _open(context, copy.id);
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  TemplateDef template,
  int recordCount,
) async {
  final bool confirmed = await showAppConfirm(
    context,
    title: Copy.templatesDeleteTitle(template.name),
    message: Copy.templatesDeleteMessage(
      fields: template.fields.length,
      records: recordCount,
    ),
    confirmLabel: Copy.templatesDelete,
    destructive: true,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  await ref
      .read(templateRepositoryProvider)
      .delete(template.id, reason: _deleteReason);
}

void _open(BuildContext context, String id) {
  context.go(TemplateLocations.detail(context, id));
}

/// Live templates for the open project. Kept alive so the list and create
/// form share one watch (FE-STATE-09).
final StreamProvider<List<TemplateDef>> templateListProvider =
    StreamProvider<List<TemplateDef>>((Ref ref) {
      final String? projectId = ref.watch(currentProjectProvider);
      if (projectId == null || projectId.isEmpty) {
        return Stream<List<TemplateDef>>.value(const <TemplateDef>[]);
      }
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    });

/// How many records use each template id. Defaults to none until the records
/// feature watches captures; tests override this map.
final Provider<Map<String, int>> templateRecordCountsProvider =
    Provider<Map<String, int>>((Ref _) {
      return const <String, int>{};
    });

const String _deleteReason = 'Removed from the project.';
