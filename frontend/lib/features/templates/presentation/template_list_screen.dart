import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/template_def.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'template_duplicate_action.dart';
import 'template_list_filter.dart';
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
      title: projectId == null ? Copy.navTemplates : Copy.projectTemplatesTitle,
      showAppBar: false,
      inset: false,
      scrollable: false,
      footer: value.hasValue
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppButton(
                  label: (value.asData?.value.isEmpty ?? true)
                      ? Copy.templatesAddChoices
                      : Copy.templatesAddMore,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: () => unawaited(_addTemplates(context)),
                ),
                const SizedBox(height: Space.x2),
                AppPrimaryAction(
                  label: Copy.templatesCreate,
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
        onRetry: () => ref.invalidate(templateListProvider),
        data: (List<TemplateDef> rows) {
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
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.x4,
                  Space.x1,
                  Space.x4,
                  Space.x2,
                ),
                child: AppSearchField(
                  hint: Copy.search,
                  text: query,
                  onChanged: (String text) {
                    ref.read(templateListQueryProvider.notifier).set(text);
                  },
                  onFilter: () =>
                      unawaited(showTemplateListFilters(context, ref, rows)),
                  activeFilterCount: kinds.length,
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? (rows.isEmpty
                          ? _empty()
                          : AppEmptyState(
                              icon: AppIcons.searchEmpty,
                              headline: Copy.templatesNoMatch,
                              message: kinds.isEmpty
                                  ? Copy.searchNoMatchMessage
                                  : Copy.searchFilterNoMatchMessage,
                            ))
                    : ListView(
                        children: <Widget>[
                          for (final TemplateDef template in visible)
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
              ),
            ],
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
        label: Copy.templatesEdit,
        icon: AppIcons.edit,
        onTap: () => unawaited(_rename(context, ref, template)),
      ),
      AppOverflowAction(
        label: Copy.templatesOpen,
        icon: AppIcons.template,
        onTap: () => _open(context, template.id),
      ),
      AppOverflowAction(
        label: Copy.projectsDuplicate,
        icon: AppIcons.duplicate,
        onTap: () => unawaited(_duplicate(context, ref, template)),
      ),
      AppOverflowAction(
        label: Copy.templatesExport,
        icon: AppIcons.export,
        onTap: () =>
            context.go(TemplateLocations.child(context, template.id, 'export')),
      ),
      AppOverflowAction(
        label: Copy.templatesImport,
        icon: AppIcons.import,
        onTap: () => context.go(TemplateLocations.import(context)),
      ),
      if (recordCount == 0)
        AppOverflowAction(
          label: Copy.templatesDelete,
          icon: AppIcons.delete,
          onTap: () => unawaited(_delete(context, ref, template, recordCount)),
        ),
    ];
  }
}

/// The empty list names the next step; the footer's add action offers it
/// (FE-SIMP-11), so the page has one add button, not two.
Widget _empty() {
  return const AppEmptyState(
    icon: AppIcons.template,
    headline: Copy.templatesEmptyHeadline,
    message: Copy.templatesAddEmptyMessage,
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

/// How many records use each template id: the records the project home
/// lists. Empty while loading, after a failure and with no project open.
final Provider<Map<String, int>> templateRecordCountsProvider =
    Provider<Map<String, int>>((Ref ref) {
      return ref.watch(_templateRecordCountStreamProvider).asData?.value ??
          const <String, int>{};
    });

final StreamProvider<Map<String, int>> _templateRecordCountStreamProvider =
    StreamProvider<Map<String, int>>((Ref ref) {
      final String? projectId = ref.watch(currentProjectProvider);
      if (projectId == null || projectId.isEmpty) {
        return Stream<Map<String, int>>.value(const <String, int>{});
      }
      return ref
          .watch(projectRepositoryProvider)
          .watchTemplateRecordCounts(projectId, statuses: capturedItemStatuses);
    }, retry: (int _, Object _) => null);

const String _deleteReason = 'Removed from the project.';

/// Query for the template list. Ephemeral (FE-STATE-02).
final NotifierProvider<TemplateListQuery, String> templateListQueryProvider =
    NotifierProvider<TemplateListQuery, String>(
      TemplateListQuery.new,
      retry: (int _, Object _) => null,
    );

/// Holds the template-list search text.
final class TemplateListQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query.
  void set(String value) => state = value;
}

Future<void> _addTemplates(BuildContext context) async {
  await showAppSheet<void>(
    context,
    title: Copy.templatesAddChoices,
    contentSized: true,
    builder: (BuildContext sheetContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppListTile(
            title: Copy.templatesUpload,
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.go(TemplateLocations.import(context));
            },
          ),
          AppListTile(
            title: Copy.templatesUseExisting,
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

Future<void> _rename(
  BuildContext context,
  WidgetRef ref,
  TemplateDef template,
) async {
  final String? name = await showAppSheet<String>(
    context,
    title: Copy.templatesEdit,
    contentSized: true,
    builder: (BuildContext sheetContext) {
      return _RenameTemplate(initial: template.name);
    },
  );
  if (name == null || !context.mounted) {
    return;
  }
  await ref
      .read(templateRepositoryProvider)
      .save(template.copyWith(name: name));
}

class _RenameTemplate extends StatefulWidget {
  const _RenameTemplate({required this.initial});

  final String initial;

  @override
  State<_RenameTemplate> createState() => _RenameTemplateState();
}

class _RenameTemplateState extends State<_RenameTemplate> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppTextField(label: Copy.projectName, controller: _name),
        if (_error != null) Text(_error!),
        AppButton(
          label: Copy.save,
          onPressed: () {
            final String trimmed = _name.text.trim();
            if (trimmed.isEmpty) {
              setState(() => _error = Copy.nameRequired);
              return;
            }
            Navigator.of(context).pop(trimmed);
          },
        ),
      ],
    );
  }
}
