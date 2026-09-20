import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'field_delete_action.dart';
import 'field_reorder.dart';
import 'template_list_screen.dart' show templateListProvider;

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
    final Map<String, int> valueCounts = ref.watch(fieldValueCountsProvider);
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
                icon: Icons.rule,
                onTap: () => _openRequired(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.identityFieldsTitle,
                icon: Icons.fingerprint,
                onTap: () => _openIdentity(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.outputMappingTitle,
                icon: Icons.view_column_outlined,
                onTap: () => _openOutput(context, template.id),
              ),
              AppOverflowAction(
                label: Copy.templateMigrationTitle,
                icon: Icons.upgrade,
                onTap: () => _openMigrate(context, template.id),
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
          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: loaded.fields.length,
            proxyDecorator: (Widget child, int _, Animation<double> _) {
              return child;
            },
            onReorderItem: (int from, int to) {
              unawaited(
                ref
                    .read(_fieldListProvider.notifier)
                    .reorder(context, loaded, from, to),
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final FieldDef field = loaded.fields[index];
              return _FieldRow(
                key: ValueKey<String>(field.fieldKey),
                template: loaded,
                field: field,
                index: index,
                last: index == loaded.fields.length - 1,
                valueCount: valueCounts[field.fieldKey] ?? 0,
              );
            },
          );
        },
      ),
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
    required this.last,
    required this.valueCount,
  });

  final TemplateDef template;
  final FieldDef field;
  final int index;
  final bool last;
  final int valueCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppListTile(
      title: field.label,
      subtitle: Copy.fieldTypeLabel(field.type.name),
      status: _pill(field.requiredness),
      onTap: () => _openEdit(context, template.id, field.fieldKey),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            icon: Icons.keyboard_arrow_up,
            semanticLabel: Copy.fieldMoveUp(field.label),
            tooltip: Copy.fieldMoveUp(field.label),
            outlined: false,
            onPressed: index == 0
                ? null
                : () => unawaited(
                    ref
                        .read(_fieldListProvider.notifier)
                        .moveUp(context, template, index),
                  ),
          ),
          AppIconButton(
            icon: Icons.keyboard_arrow_down,
            semanticLabel: Copy.fieldMoveDown(field.label),
            tooltip: Copy.fieldMoveDown(field.label),
            outlined: false,
            onPressed: last
                ? null
                : () => unawaited(
                    ref
                        .read(_fieldListProvider.notifier)
                        .moveDown(context, template, index),
                  ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: AppIconButton(
              icon: Icons.drag_handle,
              semanticLabel: Copy.fieldReorder(field.label),
              tooltip: Copy.fieldReorder(field.label),
              outlined: false,
            ),
          ),
          AppOverflowMenu(
            items: <AppOverflowAction>[
              AppOverflowAction(
                label: Copy.templatesEditField,
                icon: Icons.edit_outlined,
                onTap: () => _openEdit(context, template.id, field.fieldKey),
              ),
              AppOverflowAction(
                label: Copy.templatesDeleteField,
                icon: Icons.delete_outline,
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

Widget _empty(BuildContext context, String templateId) {
  return AppEmptyState(
    icon: Icons.view_list_outlined,
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

  Future<void> reorder(
    BuildContext context,
    TemplateDef template,
    int from,
    int to,
  ) {
    return _save(
      context,
      template,
      FieldReorder.moved(template.fields, from, to),
    );
  }

  Future<void> moveUp(BuildContext context, TemplateDef template, int index) {
    return _save(
      context,
      template,
      FieldReorder.movedUp(template.fields, index),
    );
  }

  Future<void> moveDown(BuildContext context, TemplateDef template, int index) {
    return _save(
      context,
      template,
      FieldReorder.movedDown(template.fields, index),
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
  context.go(_addLocation(templateId));
}

void _openRequired(BuildContext context, String templateId) {
  context.go(_requiredLocation(templateId));
}

void _openIdentity(BuildContext context, String templateId) {
  context.go(_identityLocation(templateId));
}

void _openOutput(BuildContext context, String templateId) {
  context.go(_outputLocation(templateId));
}

void _openMigrate(BuildContext context, String templateId) {
  context.go(_migrateLocation(templateId));
}

void _openEdit(BuildContext context, String templateId, String fieldKey) {
  context.go(_editLocation(templateId, fieldKey));
}

/// Must match [AppRoutes.templateFieldCreate] and [AppRoutes.templateField].
const String _templatesRoot = '/templates';
const String _fieldsSegment = 'fields';
const String _newSegment = 'new';
const String _requiredSegment = 'required';
const String _identitySegment = 'identity';
const String _outputSegment = 'output';
const String _migrateSegment = 'migrate';

String _addLocation(String id) {
  return '$_templatesRoot/${Uri.encodeComponent(id)}/$_fieldsSegment/'
      '$_newSegment';
}

String _editLocation(String id, String fieldKey) {
  return '$_templatesRoot/${Uri.encodeComponent(id)}/$_fieldsSegment/'
      '${Uri.encodeComponent(fieldKey)}';
}

String _requiredLocation(String id) {
  return '$_templatesRoot/${Uri.encodeComponent(id)}/$_requiredSegment';
}

String _identityLocation(String id) {
  return '$_templatesRoot/${Uri.encodeComponent(id)}/$_identitySegment';
}

String _outputLocation(String id) {
  return '$_templatesRoot/${Uri.encodeComponent(id)}/$_outputSegment';
}

String _migrateLocation(String id) {
  return '$_templatesRoot/${Uri.encodeComponent(id)}/$_migrateSegment';
}
