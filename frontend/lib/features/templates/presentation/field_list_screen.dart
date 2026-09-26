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
import '../templates.dart' show templateRepositoryProvider;
import 'field_delete_action.dart';
import 'field_list_filter.dart';
import 'field_reorder.dart';
import 'template_list_screen.dart' show templateListProvider;
import 'template_locations.dart';

/// The one screen where a template's fields are added, edited, reordered
/// and retired.
class FieldListScreen extends ConsumerWidget {
  /// Creates the list for [templateId].
  const FieldListScreen({super.key, required this.templateId});

  /// Template whose fields this screen manages.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TemplateDef?> value = ref
        .watch(templateListProvider)
        .whenData(_pick);
    final TemplateDef? template = value.asData?.value;
    return AppPage(
      key: const ValueKey<String>('route-template-fields'),
      title: template?.name ?? Copy.templateFieldsTitle,
      scrollable: false,
      overflow: template == null
          ? const <AppOverflowAction>[]
          : <AppOverflowAction>[
              AppOverflowAction(
                label: Copy.requiredColumnsTitle,
                icon: AppIcons.rules,
                onTap: () => _openRequired(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.identityFieldsTitle,
                icon: AppIcons.identity,
                onTap: () => _openIdentity(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.outputMappingTitle,
                icon: AppIcons.columns,
                onTap: () => _openOutput(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.templateMigrationTitle,
                icon: AppIcons.migrate,
                onTap: () => _openMigrate(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.rowAliasesTitle,
                icon: AppIcons.aliases,
                onTap: () => _openAliases(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.checklistTitle,
                icon: AppIcons.checklist,
                onTap: () => _openChecklist(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.detectionProfileTitle,
                icon: AppIcons.detection,
                onTap: () => _openDetection(context, template.id),
              ),
            ],
      footer: template == null
          ? null
          : AppPrimaryAction(
              label: Copy.templatesAddField,
              onPressed: () => _openAdd(context, template.id),
            ),
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null || row.fields.isEmpty,
        empty: () => _empty(context, template?.id ?? templateId),
        onRetry: () => ref.invalidate(templateListProvider),
        data: (TemplateDef? row) {
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
                  hint: Copy.search,
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
    if (fields.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.search,
        headline: Copy.fieldsNoMatch,
        message: filtered ? Copy.searchFilterNoMatchMessage : Copy.search,
      );
    }
    final Map<String, int> valueCounts = ref.watch(fieldValueCountsProvider);
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
            valueCount: valueCounts[field.fieldKey] ?? 0,
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
                title: _sectionTitle(requiredness),
              ),
            ),
            _section(
              context,
              ref,
              loaded,
              sections[requiredness]!,
              valueCounts,
            ),
          ],
      ],
    );
  }

  Widget _section(
    BuildContext context,
    WidgetRef ref,
    TemplateDef loaded,
    List<int> slots,
    Map<String, int> valueCounts,
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
          valueCount: valueCounts[field.fieldKey] ?? 0,
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
    required this.valueCount,
    this.dragIndex,
  });

  final TemplateDef template;
  final FieldDef field;

  /// Stored position of [field] in [template].
  final int index;

  /// Stored positions of the fields in [field]'s section, in order.
  final List<int> slots;

  final int valueCount;

  /// Place in its section's reorderable list; null lists it without drag.
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int position = slots.indexOf(index);
    final int? dragIndex = this.dragIndex;
    return AppListTile(
      title: field.label,
      subtitle: Copy.fieldRowSubtitle(
        typeLabel: Copy.fieldTypeLabel(field.type.name),
        requiredField: field.requiredness == Requiredness.required,
        calculated: field.type == FieldType.computed,
        fromPhotos: _mentioned(template.detection, field.fieldKey),
        pinnedContext: field.stickable,
        contextLevel: field.contextLevel,
        defaultValue: field.defaultValue,
      ),
      status: _pill(field.requiredness),
      onTap: () => _openEdit(context, template.id, field.fieldKey),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Up and down stay inside the field's section (FBK0000003).
          AppIconButton(
            icon: AppIcons.moveUp,
            semanticLabel: Copy.fieldMoveUp(field.label),
            tooltip: Copy.fieldMoveUp(field.label),
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
            semanticLabel: Copy.fieldMoveDown(field.label),
            tooltip: Copy.fieldMoveDown(field.label),
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
                semanticLabel: Copy.fieldReorder(field.label),
                tooltip: Copy.fieldReorder(field.label),
                outlined: false,
              ),
            ),
          AppOverflowMenu(
            items: <AppOverflowAction>[
              AppOverflowAction(
                label: Copy.templatesEditField,
                icon: AppIcons.edit,
                onTap: () => _openEdit(context, template.id, field.fieldKey),
              ),
              AppOverflowAction(
                label: Copy.templatesDeleteField,
                icon: AppIcons.delete,
                onTap: () => unawaited(
                  ref
                      .read(_fieldListProvider.notifier)
                      .delete(
                        context,
                        template: template,
                        field: field,
                        valueCount: valueCount,
                      ),
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

String _sectionTitle(Requiredness requiredness) {
  return switch (requiredness) {
    Requiredness.required => Copy.fieldRequired,
    Requiredness.recommended => Copy.fieldRecommended,
    Requiredness.optional => Copy.fieldOptional,
  };
}

bool _matchesQuery(FieldDef field, String needle) {
  return needle.isEmpty ||
      field.label.toLowerCase().contains(needle) ||
      field.fieldKey.toLowerCase().contains(needle) ||
      field.type.name.toLowerCase().contains(needle);
}

Widget _empty(BuildContext context, String templateId) {
  return AppEmptyState(
    icon: AppIcons.fields,
    headline: Copy.templatesFieldsEmptyHeadline,
    message: Copy.templatesFieldsEmptyMessage,
    actionLabel: Copy.templatesAddField,
    onAction: () => _openAdd(context, templateId),
  );
}

AppStatusPill _pill(Requiredness requiredness) {
  return AppStatusPill.badge(
    status: switch (requiredness) {
      Requiredness.required => RecordStatus.needsReview,
      Requiredness.recommended => RecordStatus.queued,
      Requiredness.optional => RecordStatus.draft,
    },
    label: switch (requiredness) {
      Requiredness.required => Copy.fieldRequired,
      Requiredness.recommended => Copy.fieldRecommended,
      Requiredness.optional => Copy.fieldOptional,
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
    required int valueCount,
  }) async {
    final Result<TemplateDef>? result = await FieldDeleteAction.confirmAndApply(
      context: context,
      templates: ref.read(templateRepositoryProvider),
      template: template,
      field: field,
      valueCount: valueCount,
    );
    if (result == null || !context.mounted) {
      return;
    }
    switch (result) {
      case Success<TemplateDef>():
        return;
      case FailureResult<TemplateDef>(:final failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
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
        showAppSnack(context, failure.message, tone: SnackTone.error);
    }
  }
}

final NotifierProvider<_FieldList, bool> _fieldListProvider =
    NotifierProvider<_FieldList, bool>(
      _FieldList.new,
      retry: (int _, Object _) => null,
    );

/// How many records hold a value for each field key on the open template.
/// Defaults to none until the records feature watches captures; tests
/// override this map.
final Provider<Map<String, int>> fieldValueCountsProvider =
    Provider<Map<String, int>>((Ref _) {
      return const <String, int>{};
    });

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

/// Holds the field-list search text.
final class FieldListQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query.
  void set(String value) => state = value;
}
