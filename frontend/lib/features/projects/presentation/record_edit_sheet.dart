import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/project_repository.dart';
import 'record_edit_controller.dart';
import 'record_field_draft.dart';
import 'record_field_input.dart';

/// Opens the editor for [row] as a sheet, or a side panel on expanded
/// windows (FE-CONS-05).
Future<void> showRecordEditSheet(BuildContext context, ProjectRecordRow row) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<void>(
    context,
    title: localCopy.recordEdit,
    builder: (BuildContext _) => RecordEditSheet(row: row),
  );
}

/// Every editable field of a captured record's template, each in the input
/// its type names, prefilled with what is stored, and one Save.
class RecordEditSheet extends ConsumerStatefulWidget {
  /// Creates the editor for [row].
  const RecordEditSheet({required this.row, super.key});

  /// The record being edited.
  final ProjectRecordRow row;

  @override
  ConsumerState<RecordEditSheet> createState() => _RecordEditSheetState();
}

class _RecordEditSheetState extends ConsumerState<RecordEditSheet> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _valueOf(RecordEditEntry entry) {
    return ref.read(recordFieldDraftProvider(widget.row.id))[entry.fieldKey] ??
        entry.initial;
  }

  TextEditingController _controllerFor(RecordEditEntry entry) {
    return _controllers.putIfAbsent(
      entry.fieldKey,
      () => TextEditingController(text: entry.initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TemplateDef?> template = ref.watch(
      recordTemplateProvider(widget.row.templateId),
    );
    final RecordEditState state = ref.watch(
      recordEditControllerProvider(widget.row.id),
    );
    ref.watch(recordFieldDraftProvider(widget.row.id));
    return AsyncValueView<TemplateDef?>(
      value: template,
      onRetry: () =>
          ref.invalidate(recordTemplateProvider(widget.row.templateId)),
      data: (TemplateDef? loaded) {
        final LocalizedCopy localCopy = Copy.of(context);

        final List<RecordEditEntry> entries = recordEditEntries(
          template: loaded,
          row: widget.row,
        );
        if (entries.isEmpty) {
          return AppEmptyState(
            icon: AppIcons.fields,
            headline: localCopy.recordEditNoFieldsHeadline,
            message: localCopy.recordEditNoFieldsMessage,
          );
        }
        final Failure? failure = state.failure;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.x3,
            Space.x0,
            Space.x3,
            Space.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ListView.separated(
                  key: const ValueKey<String>('record-edit-fields'),
                  itemCount: entries.length,
                  separatorBuilder: (BuildContext _, int _) =>
                      const SizedBox(height: Space.x3),
                  itemBuilder: (BuildContext context, int index) {
                    final RecordEditEntry entry = entries[index];
                    return RecordFieldInput(
                      entry: entry,
                      text: _valueOf(entry),
                      controller: entry.field == null
                          ? _controllerFor(entry)
                          : null,
                      onChanged: (String text) => ref
                          .read(
                            recordFieldDraftProvider(widget.row.id).notifier,
                          )
                          .set(entry.fieldKey, text),
                    );
                  },
                ),
              ),
              if (failure != null) ...<Widget>[
                const SizedBox(height: Space.x2),
                AppBanner(
                  message: failure.message,
                  icon: AppIcons.error,
                  tone: SnackTone.error,
                ),
              ],
              const SizedBox(height: Space.x3),
              AppPrimaryAction(
                label: localCopy.save,
                busy: state.saving,
                onPressed: () => unawaited(_save(entries)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(List<RecordEditEntry> entries) async {
    final List<RecordFieldEdit> edits = <RecordFieldEdit>[
      for (final RecordEditEntry entry in entries)
        if (_changed(entry))
          (
            fieldKey: entry.fieldKey,
            value: _valueOf(entry),
            stored: entry.stored,
          ),
    ];
    final NavigatorState navigator = Navigator.of(context);
    if (edits.isEmpty) {
      navigator.pop();
      return;
    }
    final Result<void> saved = await ref
        .read(recordEditControllerProvider(widget.row.id).notifier)
        .save(edits);
    if (!mounted) {
      return;
    }
    if (saved is Success<void>) {
      navigator.pop();
    }
  }

  bool _changed(RecordEditEntry entry) =>
      recordFieldChanged(entry, _valueOf(entry));
}

/// Whether [text] is a change worth writing for [entry]: new text on a
/// field with no stored row, or text that differs from what is stored.
bool recordFieldChanged(RecordEditEntry entry, String text) {
  if (!entry.stored) {
    return text.trim().isNotEmpty;
  }
  return text != entry.initial;
}

/// One editable field on the sheet. [field] is null for a stored value the
/// template no longer declares, which is edited as plain text.
typedef RecordEditEntry = ({
  String fieldKey,
  String label,
  String initial,
  bool stored,
  TextInputType? keyboard,
  bool multiline,
  FieldDef? field,
});

/// The fields [row] can be edited in: [template]'s visible, person-entered
/// fields in template order, then any stored value the template no longer
/// declares. Each starts from the refined value, falling back to the raw one.
List<RecordEditEntry> recordEditEntries({
  required TemplateDef? template,
  required ProjectRecordRow row,
}) {
  final Map<String, ProjectRecordFieldValue> stored =
      <String, ProjectRecordFieldValue>{
        for (final ProjectRecordFieldValue field in row.fields)
          field.fieldKey: field,
      };
  final List<FieldDef> fields = <FieldDef>[
    for (final FieldDef field in template?.fields ?? const <FieldDef>[])
      if (!field.hidden &&
          field.inputMode != InputMode.auto &&
          field.type != FieldType.computed)
        field,
  ]..sort((FieldDef a, FieldDef b) => a.sortOrder.compareTo(b.sortOrder));
  final Set<String> declared = <String>{
    for (final FieldDef field in template?.fields ?? const <FieldDef>[])
      field.fieldKey,
  };
  return <RecordEditEntry>[
    for (final FieldDef field in fields)
      (
        fieldKey: field.fieldKey,
        label: field.label.isEmpty ? field.fieldKey : field.label,
        initial: _initial(stored[field.fieldKey]),
        stored: stored.containsKey(field.fieldKey),
        keyboard: _keyboardFor(field.type),
        multiline: field.type == FieldType.longText,
        field: field,
      ),
    for (final ProjectRecordFieldValue field in row.fields)
      if (!declared.contains(field.fieldKey))
        (
          fieldKey: field.fieldKey,
          label: field.fieldKey,
          initial: _initial(field),
          stored: true,
          keyboard: null,
          multiline: false,
          field: null,
        ),
  ];
}

String _initial(ProjectRecordFieldValue? value) {
  if (value == null) {
    return '';
  }
  return value.refined.isNotEmpty ? value.refined : value.raw;
}

TextInputType? _keyboardFor(FieldType type) {
  return switch (type) {
    FieldType.number => TextInputType.number,
    FieldType.decimal || FieldType.currency || FieldType.percentage =>
      const TextInputType.numberWithOptions(decimal: true),
    FieldType.longText => TextInputType.multiline,
    _ => null,
  };
}

/// The template a record was captured with; null when it was removed.
final recordTemplateProvider = FutureProvider.autoDispose
    .family<TemplateDef?, String>((Ref ref, String templateId) async {
      final Result<TemplateDef?> loaded = await ref
          .watch(templateRepositoryProvider)
          .byId(templateId);
      return switch (loaded) {
        Success<TemplateDef?>(:final TemplateDef? value) => value,
        FailureResult<TemplateDef?>(:final Failure failure) => throw failure,
      };
    }, retry: (int _, Object _) => null);
