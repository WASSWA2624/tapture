import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/record_entry.dart';
import '../domain/record_value.dart';

export 'package:tapture/features/templates/templates.dart'
    show editorValueOf, storedTextOf;

/// One record value corrected through the shared inline [FieldEditor]
/// (task 097), so the input, validation and formatting are the ones capture
/// uses (FE-CONS-01). The value travels as the text a record value stores.
///
/// Only a field the record's template declares is edited here; a retired
/// value is shown read-only by its page and never reaches this input.
/// Automatic values reveal the editor only after an explicit correction action.
class RecordFieldInput extends StatefulWidget {
  /// Creates the input for [entry], showing [text].
  const RecordFieldInput({
    required this.entry,
    required this.text,
    required this.onChanged,
    super.key,
  });

  /// The field being filled, with what the record holds for it.
  final RecordEditEntry entry;

  /// Its current text: what was typed, else what is stored.
  final String text;

  /// Receives the new text.
  final ValueChanged<String> onChanged;

  @override
  State<RecordFieldInput> createState() => _RecordFieldInputState();
}

class _RecordFieldInputState extends State<RecordFieldInput>
    with StateRefresh<RecordFieldInput> {
  bool _correcting = false;

  @override
  void didUpdateWidget(RecordFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.fieldKey != widget.entry.fieldKey) _correcting = false;
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    final RecordEditEntry entry = widget.entry;
    final String text = widget.text;
    final FieldDef field = entry.field;
    final RecordValue? stored = entry.value;
    final bool correctable =
        FieldInputPolicy.canCorrect(field) && !(stored?.retired ?? false);
    final bool automatic =
        field.inputMode == InputMode.auto ||
        field.autoFill != null ||
        stored?.valueSource == ValueSource.auto ||
        stored?.valueSource == ValueSource.context;
    if (!correctable || (automatic && !_correcting)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppListTile(
            key: ValueKey<String>('record-field-original-${entry.fieldKey}'),
            title: entry.label,
            subtitle: text.isEmpty
                ? localCopy.recordFieldEmpty
                : _preview(context, field.type, text),
            dense: true,
          ),
          if (correctable)
            AppButton(
              key: ValueKey<String>('record-field-correct-${entry.fieldKey}'),
              label: localCopy.recordCorrectAutomaticValue,
              variant: AppButtonVariant.secondary,
              expand: true,
              // Revealing the editor is UI-only. Its callback changes the
              // draft, which becomes durable only when the person saves.
              onPressed: () => refresh(() => _correcting = true),
            ),
        ],
      );
    }
    final bool untouched = text == entry.initial;
    final Widget editor = FieldEditor(
      key: ValueKey<String>('record-field-input-${entry.fieldKey}'),
      field: fieldEditorField(field.copyWith(label: entry.label)),
      value: FieldValue(
        fieldKey: field.fieldKey,
        value: editorValueOf(field.type, text),
        // What is stored keeps its own source until the operator changes it.
        source: untouched
            ? stored?.valueSource ?? ValueSource.manual
            : ValueSource.manual,
        verified: untouched && (stored?.verified ?? false),
      ),
      onChanged: (FieldValue next) =>
          widget.onChanged(storedTextOf(field.type, next.value)),
    );
    if (!(stored?.evidenceRemoved ?? false)) {
      return editor;
    }
    // Every photo the value was read from is gone; the value is kept, and
    // the mark says it has nothing left to be checked against.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        editor,
        const SizedBox(height: Space.x1),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppStatusPill.badge(
            key: ValueKey<String>('record-evidence-removed-${entry.fieldKey}'),
            status: RecordStatus.needsReview,
            label: localCopy.recordValueEvidenceRemoved,
          ),
        ),
      ],
    );
  }
}

/// A retired [value] as a read-only row: its field's label ([template]'s
/// when it still declares the key, else the key itself), what it holds and
/// a Retired pill, with no tap, so it can be read but never edited or
/// deleted.
AppListTile recordRetiredValueTile(
  RecordValue value, {
  TemplateDef? template,
  LocalizedCopy? localizedCopy,
}) {
  String title = value.fieldKey;
  for (final FieldDef field in template?.fields ?? const <FieldDef>[]) {
    if (field.fieldKey == value.fieldKey && field.label.isNotEmpty) {
      title = field.label;
      break;
    }
  }
  return AppListTile(
    key: ValueKey<String>('record-retired-${value.fieldKey}'),
    title: title,
    subtitle: value.hasValue
        ? value.display
        : (localizedCopy ?? Copy.english).recordFieldEmpty,
    dense: true,
    status: AppStatusPill.badge(
      status: RecordStatus.archived,
      label: (localizedCopy ?? Copy.english).recordValueRetired,
    ),
  );
}

/// One field a person can edit on a record: the template [field], the
/// [label] it shows, the [initial] text the record displays for it, whether
/// the record already holds a value for it ([stored]), and that [value].
typedef RecordEditEntry = ({
  String fieldKey,
  String label,
  String initial,
  bool stored,
  FieldDef field,
  RecordValue? value,
});

/// The fields of [record] a person can edit, in [template]'s order: every
/// live field permitted by the shared correction policy. A field
/// whose value was retired is left out; its value stays read-only. Each
/// starts from what the record displays for it (approved, else refined,
/// else raw). No template, no editable field.
List<RecordEditEntry> recordEditEntries({
  required TemplateDef? template,
  required RecordEntry record,
}) {
  if (template == null) {
    return const <RecordEditEntry>[];
  }
  final List<FieldDef> fields = <FieldDef>[
    for (final FieldDef field in template.fields)
      if (FieldInputPolicy.canCorrect(field)) field,
  ];
  final List<int> order = List<int>.generate(fields.length, (int i) => i)
    ..sort((int a, int b) {
      final int bySort = fields[a].sortOrder.compareTo(fields[b].sortOrder);
      return bySort != 0 ? bySort : a.compareTo(b);
    });
  return <RecordEditEntry>[
    for (final int index in order)
      if (!(record.valueOf(fields[index].fieldKey)?.retired ?? false))
        _entryFor(fields[index], record.valueOf(fields[index].fieldKey)),
  ];
}

/// The values of [record] kept after its template stopped declaring them:
/// flagged retired, or not declared by [template] (every value when the
/// template is gone). They are shown and never edited or deleted.
List<RecordValue> recordRetiredValues({
  required TemplateDef? template,
  required RecordEntry record,
}) {
  final Set<String> declared = <String>{
    for (final FieldDef field in template?.fields ?? const <FieldDef>[])
      field.fieldKey,
  };
  return <RecordValue>[
    for (final RecordValue value in record.values)
      if (value.retired || !declared.contains(value.fieldKey)) value,
  ];
}

/// Whether [text] is a change worth writing for [entry]: text on a field
/// the record holds nothing for, or text that differs from what it shows.
bool recordFieldChanged(RecordEditEntry entry, String text) {
  if (!entry.stored) {
    return text.trim().isNotEmpty;
  }
  return text != entry.initial;
}

RecordEditEntry _entryFor(FieldDef field, RecordValue? value) {
  return (
    fieldKey: field.fieldKey,
    label: field.label.isEmpty ? field.fieldKey : field.label,
    initial: field.type == FieldType.consent
        ? value?.approved ?? value?.refined ?? value?.raw ?? ''
        : value?.display ?? '',
    stored: value != null,
    field: field,
    value: value,
  );
}

String _preview(BuildContext context, FieldType type, String text) {
  final Object? value = editorValueOf(type, text);
  if (value is! DateTime) return text;
  final String locale = Localizations.localeOf(context).toString();
  return switch (type) {
    FieldType.date => DateFormat.yMd(locale).format(value),
    FieldType.time => DateFormat.Hm(locale).format(value),
    FieldType.dateTime => DateFormat.yMd(locale).add_Hm().format(value),
    _ => text,
  };
}
