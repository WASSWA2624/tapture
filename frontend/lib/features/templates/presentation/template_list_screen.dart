import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_list_viewport.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/template_def.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'shipped_picker_screen.dart';
import 'template_actions.dart';
import 'template_list_filter.dart';
import 'template_list_query.dart';
import 'template_locations.dart';

export 'template_list_query.dart';

/// A project's templates, each row showing field and record counts.
class TemplateListScreen extends ConsumerWidget {
  /// Creates the list. [projectId] keeps navigation inside that project.
  const TemplateListScreen({this.projectId, super.key});

  /// Project that opened this list, when the route is project-scoped.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projectId == null) {
      return const ShippedPickerScreen(root: true);
    }
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<List<TemplateDef>> value = ref.watch(
      templateProjectListProvider(projectId!),
    );
    final Map<String, int> recordCounts = ref.watch(
      templateRecordCountsProvider(projectId!),
    );
    return AppPage(
      key: const ValueKey<String>('route-templates'),
      title: projectId == null
          ? localCopy.navTemplates
          : localCopy.projectTemplatesTitle,
      showAppBar: false,
      inset: false,
      scrollable: false,
      footer: value.hasValue
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppButton(
                  label: (value.asData?.value.isEmpty ?? true)
                      ? localCopy.templatesAddChoices
                      : localCopy.templatesAddMore,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: () => unawaited(_addTemplates(context)),
                ),
                const SizedBox(height: Space.x2),
                AppPrimaryAction(
                  label: localCopy.templatesCreate,
                  onPressed: () => context.go(
                    TemplateLocations.create(context, projectId: projectId),
                  ),
                ),
              ],
            )
          : null,
      body: AsyncValueView<List<TemplateDef>>(
        value: value,
        isEmpty: (List<TemplateDef> _) => false,
        onRetry: () => ref.invalidate(templateProjectListProvider(projectId!)),
        data: (List<TemplateDef> rows) {
          final LocalizedCopy localCopy = Copy.of(context);

          final String query = ref.watch(templateListQueryProvider);
          final Set<String> kinds = ref.watch(templateListFilterProvider);
          final String needle = query.trim().toLowerCase();
          final List<TemplateDef> visible = <TemplateDef>[
            for (final TemplateDef template in rows)
              if ((needle.isEmpty ||
                      template.name.toLowerCase().contains(needle)) &&
                  TemplateListFilter.matches(template, kinds))
                template,
          ];
          return AppListViewport(
            header: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.x4,
                Space.x1,
                Space.x4,
                Space.x2,
              ),
              child: AppSearchField(
                hint: localCopy.search,
                text: query,
                onChanged: (String text) {
                  ref.read(templateListQueryProvider.notifier).set(text);
                },
                onFilter: () =>
                    unawaited(showTemplateListFilters(context, ref, rows)),
                activeFilterCount: kinds.length,
              ),
            ),
            body: visible.isEmpty
                ? (rows.isEmpty
                      ? _empty(localizedCopy: Copy.of(context))
                      : AppEmptyState(
                          icon: AppIcons.searchEmpty,
                          headline: localCopy.templatesNoMatch,
                          message: kinds.isEmpty
                              ? localCopy.searchNoMatchMessage
                              : localCopy.searchFilterNoMatchMessage,
                        ))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (BuildContext context, int index) {
                      final TemplateDef template = visible[index];
                      return AppListTile(
                        title: template.name,
                        subtitle: localCopy.templateListSubtitle(
                          fields: template.fields.length,
                          records: recordCounts[template.id] ?? 0,
                        ),
                        trailing: AppOverflowMenu(
                          items: TemplateActions.items(
                            context,
                            ref,
                            template,
                            recordCounts[template.id] ?? 0,
                          ),
                        ),
                        onTap: () => TemplateActions.open(context, template.id),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

/// The empty list names the next step; the footer's add action offers it
/// (FE-SIMP-11), so the page has one add button, not two.
Widget _empty({LocalizedCopy? localizedCopy}) {
  return AppEmptyState(
    icon: AppIcons.template,
    headline: (localizedCopy ?? Copy.english).templatesEmptyHeadline,
    message: (localizedCopy ?? Copy.english).templatesAddEmptyMessage,
  );
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

/// A route-owned project's templates, independent of the selected project.
final templateProjectListProvider =
    StreamProvider.family<List<TemplateDef>, String>(
      (Ref ref, String id) =>
          ref.watch(templateRepositoryProvider).watchByProject(id),
      retry: (int _, Object _) => null,
    );

/// How many records use each template id: the records the project home
/// lists. Empty while loading, after a failure and with no project open.
final templateRecordCountsProvider = Provider.family<Map<String, int>, String>((
  Ref ref,
  String projectId,
) {
  return ref
          .watch(_templateRecordCountStreamProvider(projectId))
          .asData
          ?.value ??
      const <String, int>{};
});

final _templateRecordCountStreamProvider =
    StreamProvider.family<Map<String, int>, String>((
      Ref ref,
      String projectId,
    ) {
      return ref
          .watch(projectRepositoryProvider)
          .watchTemplateRecordCounts(projectId, statuses: capturedItemStatuses);
    }, retry: (int _, Object _) => null);

/// Query for the template list. Ephemeral (FE-STATE-02).
final NotifierProvider<TemplateListQuery, String> templateListQueryProvider =
    NotifierProvider<TemplateListQuery, String>(
      TemplateListQuery.new,
      retry: (int _, Object _) => null,
    );

Future<void> _addTemplates(BuildContext context) async {
  final LocalizedCopy localCopy = Copy.of(context);

  await showAppSheet<void>(
    context,
    title: localCopy.templatesAddChoices,
    contentSized: true,
    builder: (BuildContext sheetContext) {
      final LocalizedCopy localCopy = Copy.of(sheetContext);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppListTile(
            title: localCopy.templatesUpload,
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.go(TemplateLocations.import(context));
            },
          ),
          AppListTile(
            title: localCopy.templatesUseExisting,
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.go(TemplateLocations.library(context));
            },
          ),
        ],
      );
    },
  );
}
