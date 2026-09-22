import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/field_type_registry.dart';

/// Inline template fields: identity + required visible; rest behind More.
final class InlineFieldsSection extends StatefulWidget {
  /// Creates the section.
  const InlineFieldsSection({
    required this.fields,
    required this.values,
    required this.onChanged,
    this.validationErrors = const <String, String>{},
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

  @override
  State<InlineFieldsSection> createState() => _InlineFieldsSectionState();
}

class _InlineFieldsSectionState extends State<InlineFieldsSection> {
  bool _moreOpen = false;
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final TextEditingController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(FieldDef field) {
    final String text = widget.values[field.fieldKey]?.toString() ?? '';
    final TextEditingController existing = _controllers.putIfAbsent(
      field.fieldKey,
      () => TextEditingController(text: text),
    );
    if (existing.text != text && !existing.selection.isValid) {
      existing.text = text;
    }
    return existing;
  }

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
    final String? error = widget.validationErrors[field.fieldKey];
    final FieldEditorKind kind = FieldTypeRegistry.of(field.type).editor;
    return Padding(
      key: ValueKey<String>('field-${field.fieldKey}-$kind'),
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: _controllerFor(field),
        decoration: InputDecoration(labelText: field.label, errorText: error),
        onChanged: (String value) => widget.onChanged(field.fieldKey, value),
      ),
    );
  }
}
