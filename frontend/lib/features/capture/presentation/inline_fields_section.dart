import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/templates/templates.dart';

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
    super.key,
  });

  /// Template fields.
  final List<FieldDef> fields;

  /// Current values.
  final Map<String, Object?> values;

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

  @override
  State<InlineFieldsSection> createState() => _InlineFieldsSectionState();
}

class _InlineFieldsSectionState extends State<InlineFieldsSection> {
  bool _moreOpen = false;

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) {
      return const SizedBox.shrink(key: Key('inline-empty'));
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
            onPressed: () => setState(() => _moreOpen = !_moreOpen),
            child: const Text(Copy.captureMoreFields),
          ),
          if (_moreOpen)
            for (final FieldDef field in more) _field(field),
        ],
      ],
    );
  }

  Widget _field(FieldDef field) {
    final FieldEditorKind kind = FieldTypeRegistry.of(field.type).editor;
    return Padding(
      key: ValueKey<String>('field-${field.fieldKey}-$kind'),
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FieldEditor(
            field: fieldEditorField(field),
            value: FieldValue(
              fieldKey: field.fieldKey,
              value: widget.values[field.fieldKey] ?? field.defaultValue,
            ),
            onChanged: (FieldValue value) =>
                widget.onChanged(field.fieldKey, value.value),
          ),
          if (field.lookup.isNotEmpty ||
              field.type == FieldType.barcode ||
              widget.linkedFields.contains(field.fieldKey))
            Wrap(
              children: <Widget>[
                if (field.lookup.isNotEmpty && widget.onLookup != null)
                  TextButton(
                    onPressed: () => widget.onLookup!(field),
                    child: const Text(Copy.search),
                  ),
                if (field.type == FieldType.barcode && widget.onScan != null)
                  TextButton(
                    onPressed: () => widget.onScan!(field),
                    child: const Text(Copy.barcodeRescan),
                  ),
                if (widget.linkedFields.contains(field.fieldKey))
                  TextButton(
                    onPressed: () => widget.onChanged(
                      field.fieldKey,
                      widget.values[field.fieldKey],
                    ),
                    child: const Text(Copy.recordSourceLookup),
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
