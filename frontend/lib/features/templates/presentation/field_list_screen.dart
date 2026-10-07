import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../templates.dart'
    show templateMigrationRepositoryProvider, templateRepositoryProvider;
import 'field_delete_action.dart';
import 'field_list_filter.dart';
import 'field_list_query.dart';
import 'field_reorder.dart';
import 'template_editor_source.dart';
import 'template_locations.dart';

export 'field_list_query.dart';

/// The one screen where a template's fields are added, edited, reordered
/// and retired.
class FieldListScreen extends ConsumerWidget {
  /// Creates the list for [templateId].
  const FieldListScreen({super.key, required this.templateId});

  /// Template whose fields this screen manages.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<TemplateDef?> value = ref
        .watch(templateEditorSourceProvider(templateId))
        .whenData(_pick);
    final TemplateDef? template = value.asData?.value;
    return AppPage(
      key: const ValueKey<String>('route-template-fields'),
      title: template?.name ?? localCopy.templateFieldsTitle,
      scrollable: false,
      overflow: template == null
          ? const <AppOverflowAction>[]
          : <AppOverflowAction>[
              AppOverflowAction(
                label: localCopy.requiredColumnsTitle,
                icon: AppIcons.rules,
                onTap: () => _openRequired(context, template.id),
              ),
              AppOverflowAction(
                label: localCopy.identityFieldsTitle,
                icon: AppIcons.identity,
                onTap: () => _openIdentity(context, template.id),
              ),
              AppOverflowAction(
                label: localCopy.outputMappingTitle,
                icon: AppIcons.columns,
                onTap: () => _openOutput(context, template.id),
              ),
              AppOverflowAction(
                label: localCopy.templateMigrationTitle,
                icon: AppIcons.migrate,
                onTap: () => _openMigrate(context, template.id),
              ),
              AppOverflowAction(
                label: localCopy.rowAliasesTitle,
                icon: AppIcons.aliases,
                onTap: () => _openAliases(context, template.id),
              ),
              AppOverflowAction(
                label: localCopy.checklistTitle,
                icon: AppIcons.checklist,
                onTap: () => _openChecklist(context, template.id),
              ),
              AppOverflowAction(
                label: localCopy.detectionProfileTitle,
                icon: AppIcons.detection,
                onTap: () => _openDetection(context, template.id),
              ),
            ],
      footer: template == null
          ? null
          : AppPrimaryAction(
              label: localCopy.templatesAddField,
              onPressed: () => _openAdd(context, template.id),
            ),
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null || row.fields.isEmpty,
        empty: () => _empty(context, template?.id ?? templateId),
        onRetry: () => ref.invalidate(templateEditorSourceProvider(templateId)),
        data: (TemplateDef? row) {
          final LocalizedCopy localCopy = Copy.of(context);

          final TemplateDef loaded = row!;
          final String query = ref.watch(fieldListQueryProvider);
          final FieldListFacets facets = ref.watch(fieldListFilterProvider);
          final int activeFilters = FieldListFilter.activeCount(facets);
          final String needle = query.trim().toLowerCase();
          final List<FieldDef> fields = <FieldDef>[
            for (final FieldDef field in loaded.fields)
              if (_matchesQuery(field, needle) &&
                  FieldListFilter.matches(field, facets))
                field,
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
                  hint: localCopy.search,
                  text: query,
                  onChanged: (String text) {
                    ref.read(fieldListQueryProvider.notifier).set(text);
                  },
                  onFilter: () => unawaited(
                    showFieldListFilters(context, ref, loaded.fields),
                  ),
                  activeFilterCount: activeFilters,
                ),
              ),
              Expanded(
                child: _fieldList(
                  context,
                  ref,
                  loaded,
                  fields,
                  narrowed: needle.isNotEmpty || activeFilters > 0,
                  filtered: activeFilters > 0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Required fields first, then recommended, then optional, each section
  /// in stored order; a move stays inside its section, and the order
  /// capture and exports read is left as stored (FBK0000003). A search or a
  /// filter lists the matches flat, without drag.
  Widget _fieldList(
    BuildContext context,
    WidgetRef ref,
    TemplateDef loaded,
    List<FieldDef> fields, {
    required bool narrowed,
    required bool filtered,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (fields.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.search,
        headline: localCopy.fieldsNoMatch,
        message: filtered
            ? localCopy.searchFilterNoMatchMessage
            : localCopy.search,
      );
    }
    final Map<Requiredness, List<int>> sections = _sections(loaded.fields);
    if (narrowed) {
      return ListView.builder(
        itemCount: fields.length,
        itemBuilder: (BuildContext context, int index) {
          final FieldDef field = fields[index];
          final int stored = loaded.fields.indexWhere(
            (FieldDef row) => row.fieldKey == field.fieldKey,
          );
          return _FieldRow(
            key: ValueKey<String>(field.fieldKey),
            template: loaded,
            field: field,
            index: stored,
            slots: sections[field.requiredness]!,
          );
        },
      );
    }
    return CustomScrollView(
      slivers: <Widget>[
        for (final Requiredness requiredness in Requiredness.values)
          if (sections[requiredness]!.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(
              child: AppSectionHeader(
                key: ValueKey<String>('field-section-${requiredness.name}'),
                title: _sectionTitle(
                  requiredness,
                  localizedCopy: Copy.of(context),
                ),
              ),
            ),
            _section(context, ref, loaded, sections[requiredness]!),
          ],
      ],
    );
  }

  Widget _section(
    BuildContext context,
    WidgetRef ref,
    TemplateDef loaded,
    List<int> slots,
  ) {
    return SliverReorderableList(
      itemCount: slots.length,
      proxyDecorator: (Widget child, int _, Animation<double> _) => child,
      onReorderItem: (int from, int to) {
        unawaited(
          ref
              .read(_fieldListProvider.notifier)
              .reorder(context, loaded, slots, from, to),
        );
      },
      itemBuilder: (BuildContext context, int position) {
        final FieldDef field = loaded.fields[slots[position]];
        return _FieldRow(
          key: ValueKey<String>(field.fieldKey),
          template: loaded,
          field: field,
          index: slots[position],
          slots: slots,
          dragIndex: position,
        );
      },
    );
  }

  TemplateDef? _pick(List<TemplateDef> rows) {
    for (final TemplateDef row in rows) {
      if (row.id == templateId) {
        return row;
      }
    }
    return null;
  }
}

class _FieldRow extends ConsumerWidget {
  const _FieldRow({
    super.key,
    required this.template,
    required this.field,
    required this.index,
    required this.slots,
    this.dragIndex,
  });

  final TemplateDef template;
  final FieldDef field;

  /// Stored position of [field] in [template].
  final int index;

  /// Stored positions of the fields in [field]'s section, in order.
  final List<int> slots;

  /// Place in its section's reorderable list; null lists it without drag.
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final int position = slots.indexOf(index);
    final int? dragIndex = this.dragIndex;
    return AppListTile(
      title: field.label,
      subtitle: localCopy.fieldRowSubtitle(
        typeLabel: localCopy.fieldTypeLabel(field.type.name),
        requiredField: field.requiredness == Requiredness.required,
        calculated: field.type == FieldType.computed,
        fromPhotos: _mentioned(template.detection, field.fieldKey),
        pinnedContext: field.stickable,
        contextLevel: field.contextLevel,
        defaultValue: field.defaultValue,
      ),
      status: _pill(field.requiredness, localizedCopy: Copy.of(context)),
      onTap: () => _openEdit(context, template.id, field.fieldKey),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Up and down stay inside the field's section (FBK0000003).
          AppIconButton(
            icon: AppIcons.moveUp,
            semanticLabel: localCopy.fieldMoveUp(field.label),
            tooltip: localCopy.fieldMoveUp(field.label),
            outlined: false,
            onPressed: position <= 0
                ? null
                : () => unawaited(
                    ref
                        .read(_fieldListProvider.notifier)
                        .reorder(
                          context,
                          template,
                          slots,
                          position,
                          position - 1,
                        ),
                  ),
          ),
          AppIconButton(
            icon: AppIcons.moveDown,
            semanticLabel: localCopy.fieldMoveDown(field.label),
            tooltip: localCopy.fieldMoveDown(field.label),
            outlined: false,
            onPressed: position < 0 || position >= slots.length - 1
                ? null
                : () => unawaited(
                    ref
                        .read(_fieldListProvider.notifier)
                        .reorder(
                          context,
                          template,
                          slots,
                          position,
                          position + 1,
                        ),
                  ),
          ),
          if (dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex,
              child: AppIconButton(
                icon: AppIcons.reorder,
                semanticLabel: localCopy.fieldReorder(field.label),
                tooltip: localCopy.fieldReorder(field.label),
                outlined: false,
              ),
            ),
          AppOverflowMenu(
            items: <AppOverflowAction>[
              AppOverflowAction(
                label: localCopy.templatesEditField,
                icon: AppIcons.edit,
                onTap: () => _openEdit(context, template.id, field.fieldKey),
              ),
              AppOverflowAction(
                label: localCopy.templatesDeleteField,
                icon: AppIcons.delete,
                onTap: () => unawaited(
                  ref
                      .read(_fieldListProvider.notifier)
                      .delete(context, template: template, field: field),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The stored positions of each requiredness's fields, in stored order.
Map<Requiredness, List<int>> _sections(List<FieldDef> fields) {
  final Map<Requiredness, List<int>> slots = <Requiredness, List<int>>{
    for (final Requiredness requiredness in Requiredness.values)
      requiredness: <int>[],
  };
  for (int index = 0; index < fields.length; index++) {
    slots[fields[index].requiredness]!.add(index);
  }
  return slots;
}

String _sectionTitle(
  Requiredness requiredness, {
  LocalizedCopy? localizedCopy,
}) {
  return switch (requiredness) {
    Requiredness.required => (localizedCopy ?? Copy.english).fieldRequired,
    Requiredness.recommended =>
      (localizedCopy ?? Copy.english).fieldRecommended,
    Requiredness.optional => (localizedCopy ?? Copy.english).fieldOptional,
  };
}

bool _matchesQuery(FieldDef field, String needle) {
  return needle.isEmpty ||
      field.label.toLowerCase().contains(needle) ||
      field.fieldKey.toLowerCase().contains(needle) ||
      field.type.name.toLowerCase().contains(needle);
}

Widget _empty(BuildContext context, String templateId) {
  final LocalizedCopy localCopy = Copy.of(context);

  return AppEmptyState(
    icon: AppIcons.fields,
    headline: localCopy.templatesFieldsEmptyHeadline,
    message: localCopy.templatesFieldsEmptyMessage,
    actionLabel: localCopy.templatesAddField,
    onAction: () => _openAdd(context, templateId),
  );
}

AppStatusPill _pill(Requiredness requiredness, {LocalizedCopy? localizedCopy}) {
  return AppStatusPill.badge(
    status: switch (requiredness) {
      Requiredness.required => RecordStatus.needsReview,
      Requiredness.recommended => RecordStatus.queued,
      Requiredness.optional => RecordStatus.draft,
    },
    label: switch (requiredness) {
      Requiredness.required => (localizedCopy ?? Copy.english).fieldRequired,
      Requiredness.recommended =>
        (localizedCopy ?? Copy.english).fieldRecommended,
      Requiredness.optional => (localizedCopy ?? Copy.english).fieldOptional,
    },
  );
}

class _FieldList extends Notifier<bool> {
  @override
  bool build() => false;

  /// Moves the field at place [from] of the section holding stored
  /// positions [slots] to place [to]. Only that section's slots change, so
  /// a one-place move swaps the stored positions of the two fields.
  Future<void> reorder(
    BuildContext context,
    TemplateDef template,
    List<int> slots,
    int from,
    int to,
  ) {
    return _save(
      context,
      template,
      FieldReorder.movedWithin(template.fields, slots, from, to),
    );
  }

  Future<void> delete(
    BuildContext context, {
    required TemplateDef template,
    required FieldDef field,
  }) async {
    if (state) return;
    state = true;
    try {
      final Result<Map<String, int>> counts = await ref
          .read(templateMigrationRepositoryProvider)
          .fieldValueCounts(template.id);
      if (!ref.mounted || !context.mounted) return;
      final Map<String, int> values;
      switch (counts) {
        case Success<Map<String, int>>(:final value):
          values = value;
        case FailureResult<Map<String, int>>(:final failure):
          showAppSnack(
            context,
            failure.message,
            tone: SnackTone.error,
            localizedMessage: failure.explanation,
          );
          return;
      }
      final Result<TemplateDef>? result =
          await FieldDeleteAction.confirmAndApply(
            context: context,
            templates: ref.read(templateRepositoryProvider),
            template: template,
            field: field,
            valueCount: values[field.fieldKey] ?? 0,
          );
      if (result == null || !context.mounted) {
        return;
      }
      switch (result) {
        case Success<TemplateDef>():
          return;
        case FailureResult<TemplateDef>(:final failure):
          showAppSnack(
            context,
            failure.message,
            tone: SnackTone.error,
            localizedMessage: failure.explanation,
          );
      }
    } finally {
      if (ref.mounted) state = false;
    }
  }

  Future<void> _save(
    BuildContext context,
    TemplateDef template,
    List<FieldDef> fields,
  ) async {
    if (identical(fields, template.fields)) {
      return;
    }
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(template.copyWith(version: template.version + 1, fields: fields));
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case Success<TemplateDef>():
        return;
      case FailureResult<TemplateDef>(:final failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
    }
  }
}

final NotifierProvider<_FieldList, bool> _fieldListProvider =
    NotifierProvider<_FieldList, bool>(
      _FieldList.new,
      retry: (int _, Object _) => null,
    );

void _openAdd(BuildContext context, String templateId) {
  context.go(TemplateLocations.child(context, templateId, 'fields/new'));
}

void _openRequired(BuildContext context, String templateId) {
  context.go(TemplateLocations.child(context, templateId, 'required'));
}

void _openIdentity(BuildContext context, String templateId) {
  context.go(TemplateLocations.child(context, templateId, 'identity'));
}

void _openOutput(BuildContext context, String templateId) {
  context.go(TemplateLocations.child(context, templateId, 'output'));
}

void _openMigrate(BuildContext context, String templateId) {
  context.go(TemplateLocations.child(context, templateId, 'migrate'));
}

void _openAliases(BuildContext context, String templateId) {
  context.go(TemplateLocations.child(context, templateId, 'aliases'));
}

void _openChecklist(BuildContext context, String templateId) {
  context.go(TemplateLocations.child(context, templateId, 'checklist'));
}

void _openDetection(BuildContext context, String templateId) {
  context.go(TemplateLocations.child(context, templateId, 'detection'));
}

void _openEdit(BuildContext context, String templateId, String fieldKey) {
  context.go(
    '${TemplateLocations.detail(context, templateId)}/fields/${Uri.encodeComponent(fieldKey)}',
  );
}

bool _mentioned(Map<String, Object?> detection, String fieldKey) {
  if (detection.containsKey(fieldKey)) {
    return true;
  }
  for (final Object? value in detection.values) {
    if (value == fieldKey) {
      return true;
    }
    if (value is List<Object?> && value.contains(fieldKey)) {
      return true;
    }
  }
  return false;
}

/// Query for one template's field list. Ephemeral (FE-STATE-02).
final NotifierProvider<FieldListQuery, String> fieldListQueryProvider =
    NotifierProvider<FieldListQuery, String>(
      FieldListQuery.new,
      retry: (int _, Object _) => null,
    );
