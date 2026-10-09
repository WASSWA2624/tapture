import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/features/records/records.dart' show RecordValue;
import 'package:tapture/features/templates/templates.dart';

import '../domain/auto_fields.dart';

/// Inline template fields: identity + required visible; rest behind More.
final class InlineFieldsSection extends StatefulWidget {
  /// Creates the section.
  const InlineFieldsSection({
    required this.fields,
    required this.values,
    required this.onChanged,
    this.validationErrors = const <String, String>{},
    this.onLookup,
    this.onScan,
    this.linkedFields = const <String>{},
    this.showAll = false,
    this.valueSources = const <String, String>{},
    this.previewKeys = const <String>{},
    this.correctingKeys = const <String>{},
    this.onCorrect,
    super.key,
  });

  /// Template fields.
  final List<FieldDef> fields;

  /// Current values.
  final Map<String, Object?> values;

  /// Actual stored provenance, including typed clears.
  final Map<String, String> valueSources;

  /// Values that will be resolved again at first save.
  final Set<String> previewKeys;

  /// Corrections retained by the sheet when a row is filtered out.
  final Set<String> correctingKeys;

  /// Reveals an eligible automatic editor without writing a value.
  final ValueChanged<String>? onCorrect;

  /// Value change.
  final void Function(String fieldKey, Object? value) onChanged;

  /// Field key → validation message.
  final Map<String, String> validationErrors;

  /// Looks up the current value without discarding typed text.
  final ValueChanged<FieldDef>? onLookup;

  /// Opens the reusable barcode scanner for identifier fields.
  final ValueChanged<FieldDef>? onScan;

  /// Fields with retained reference-row provenance.
  final Set<String> linkedFields;

  /// Renders the supplied rows directly when their owner handles grouping.
  final bool showAll;

  @override
  State<InlineFieldsSection> createState() => _InlineFieldsSectionState();
}

class _InlineFieldsSectionState extends State<InlineFieldsSection>
    with StateRefresh {
  bool _moreOpen = false;
  final Set<String> _correcting = <String>{};

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (widget.fields.isEmpty) {
      return const SizedBox.shrink(key: Key('inline-empty'));
    }
    if (widget.showAll) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final FieldDef field in widget.fields) _field(field),
        ],
      );
    }
    final List<FieldDef> primary = widget.fields
        .where(
          (FieldDef f) => f.identity || f.requiredness == Requiredness.required,
        )
        .toList();
    final List<FieldDef> more = widget.fields
        .where(
          (FieldDef f) =>
              !f.identity && f.requiredness != Requiredness.required,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final FieldDef field in primary) _field(field),
        if (more.isNotEmpty) ...<Widget>[
          TextButton(
            onPressed: () => refresh(() => _moreOpen = !_moreOpen),
            child: Text(localCopy.captureMoreFields),
          ),
          if (_moreOpen)
            for (final FieldDef field in more) _field(field),
        ],
      ],
    );
  }

  Widget _field(FieldDef field) {
    final LocalizedCopy localCopy = Copy.of(context);

    final FieldEditorKind kind = FieldTypeRegistry.of(field.type).editor;
    final String? storedSource = widget.valueSources[field.fieldKey];
    final ValueSource source = RecordValue.sourceOf(storedSource ?? 'TYPED');
    final bool preview = widget.previewKeys.contains(field.fieldKey);
    final Object? value = widget.values.containsKey(field.fieldKey)
        ? widget.values[field.fieldKey]
        : field.defaultValue;
    final bool hasValue = value != null && value.toString().isNotEmpty;
    final bool manual = storedSource != null && source == ValueSource.manual;
    final AutoFill? effective = AutoFields.effectiveSource(field);
    final bool unavailableSource =
        switch (field.validation['_tapture']) {
          final Map<Object?, Object?> metadata => metadata['autoFill'] != null,
          _ => false,
        } ||
        (field.autoFill == AutoFill.localAddress &&
            field.type != FieldType.text);
    final bool automatic =
        !manual &&
        (field.inputMode == InputMode.auto ||
            unavailableSource ||
            effective != null ||
            field.contextLevel != null ||
            source == ValueSource.auto ||
            source == ValueSource.context);
    final bool canCorrect = FieldInputPolicy.canCorrect(field);
    final bool editing =
        canCorrect &&
        (!automatic ||
            widget.correctingKeys.contains(field.fieldKey) ||
            _correcting.contains(field.fieldKey));
    final String status = switch ((manual, preview, hasValue, source)) {
      (true, _, _, _) => localCopy.captureFieldManual,
      _ when unavailableSource => localCopy.captureFieldUnavailable,
      (_, _, true, ValueSource.context) => localCopy.captureFieldContext,
      (_, true, _, _) when effective == AutoFill.sequence =>
        localCopy.captureFieldFilledAtSave,
      (_, true, true, ValueSource.auto) => localCopy.captureFieldFilledAtSave,
      (_, _, true, ValueSource.auto) => localCopy.captureFieldAutomatic,
      (_, _, true, ValueSource.barcode) => localCopy.recordSourceBarcode,
      (_, _, true, ValueSource.lookup) => localCopy.recordSourceLookup,
      (_, _, true, ValueSource.import) => localCopy.recordSourceImported,
      (
        _,
        _,
        true,
        ValueSource.ocr ||
            ValueSource.aiVision ||
            ValueSource.aiText ||
            ValueSource.stt,
      ) =>
        localCopy.captureFieldProcessing,
      _ when automatic => localCopy.captureFieldUnavailable,
      _ when FieldInputPolicy.canExtract(field) && !hasValue =>
        localCopy.captureFieldProcessing,
      _ => localCopy.captureFieldManual,
    };
    final IconData icon = status == localCopy.captureFieldUnavailable
        ? AppIcons.error
        : status == localCopy.captureFieldFilledAtSave
        ? AppIcons.queued
        : source == ValueSource.context
        ? AppIcons.context
        : status == localCopy.captureFieldProcessing
        ? AppIcons.camera
        : source == ValueSource.auto
        ? AppIcons.ai
        : AppIcons.edit;
    return Padding(
      key: ValueKey<String>('field-${field.fieldKey}-$kind'),
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (editing)
            FieldEditor(
              wrapLabel: true,
              field: fieldEditorField(field),
              value: FieldValue(
                fieldKey: field.fieldKey,
                value: value is String
                    ? editorValueOf(field.type, value)
                    : value,
                source: source,
              ),
              onChanged: (FieldValue value) =>
                  widget.onChanged(field.fieldKey, value.value),
            )
          else if (editorValueOf(field.type, storedTextOf(field.type, value))
              case final DateTime date)
            AppDateField(
              key: ValueKey<String>('capture-field-original-${field.fieldKey}'),
              label: field.label,
              value: date,
              mode: switch (field.type) {
                FieldType.time => DateFieldMode.time,
                FieldType.dateTime => DateFieldMode.dateTime,
                _ => DateFieldMode.date,
              },
              enabled: false,
              onChanged: (_) {},
            )
          else
            AppListTile(
              key: ValueKey<String>('capture-field-original-${field.fieldKey}'),
              title: field.label,
              subtitle: hasValue
                  ? storedTextOf(field.type, value)
                  : localCopy.recordFieldEmpty,
              dense: true,
              wrapText: true,
            ),
          AppListTile(
            key: ValueKey<String>('capture-field-source-${field.fieldKey}'),
            title: status,
            leading: Icon(icon),
            dense: true,
            wrapText: true,
          ),
          if (automatic && canCorrect && !editing)
            AppButton(
              key: ValueKey<String>('capture-field-correct-${field.fieldKey}'),
              label: localCopy.recordCorrectAutomaticValue,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () {
                if (widget.onCorrect case final ValueChanged<String> correct) {
                  correct(field.fieldKey);
                } else {
                  refresh(() => _correcting.add(field.fieldKey));
                }
              },
            ),
          if (editing &&
              (field.lookup.isNotEmpty ||
                  field.type == FieldType.barcode ||
                  widget.linkedFields.contains(field.fieldKey)))
            Wrap(
              children: <Widget>[
                if (field.lookup.isNotEmpty && widget.onLookup != null)
                  TextButton(
                    onPressed: () => widget.onLookup!(field),
                    child: Text(localCopy.search),
                  ),
                if (field.type == FieldType.barcode && widget.onScan != null)
                  TextButton(
                    onPressed: () => widget.onScan!(field),
                    child: Text(localCopy.barcodeRescan),
                  ),
                if (widget.linkedFields.contains(field.fieldKey))
                  TextButton(
                    onPressed: () => widget.onChanged(
                      field.fieldKey,
                      widget.values[field.fieldKey],
                    ),
                    child: Text(localCopy.recordSourceLookup),
                  ),
              ],
            ),
          if (widget.validationErrors[field.fieldKey] case final String message)
            Text(message),
        ],
      ),
    );
  }
}
