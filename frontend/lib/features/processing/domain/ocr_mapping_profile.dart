import 'package:tapture/features/templates/domain/domain.dart'
    show FieldDef, FieldInputPolicy, TemplateDef;

/// The OCR mapper specific to one captured template version and field scope.
final class OcrMappingProfile {
  /// Builds a profile from that template's own labels, types and constraints.
  OcrMappingProfile.fromTemplate(TemplateDef template)
    : templateKey = template.templateKey,
      templateVersion = template.version,
      labelFields = List<FieldDef>.unmodifiable(template.fields),
      _patterns = <({String key, RegExp pattern})>[
        for (final FieldDef field in template.fields)
          for (final String name in _labels(field))
            if (name.trim().isNotEmpty)
              (key: field.fieldKey, pattern: _pattern(name)),
      ],
      fields = List<FieldDef>.unmodifiable(
        template.fields.where(FieldInputPolicy.canExtract),
      );

  /// Stable shipped/custom template identity.
  final String templateKey;

  /// The version whose field meanings this mapper uses.
  final int templateVersion;

  /// Eligible fields with the template's options, units and validation intact.
  final List<FieldDef> fields;

  /// Complete captured labels delimit values, including fields outside scope.
  final List<FieldDef> labelFields;

  final List<({String key, RegExp pattern})> _patterns;

  /// Matched label spans preserve collisions until the mapper reviews them.
  Iterable<({String key, int start, int end})> matches(String text) sync* {
    for (final entry in _patterns) {
      for (final RegExpMatch match in entry.pattern.allMatches(text)) {
        final String before = text.substring(0, match.start);
        final String after = text.substring(match.end).trimLeft();
        // A field name inside a value ("Model Systems") is ordinary evidence.
        // Inline parameters require their own delimiter or a clear cell break.
        if (before.trim().isNotEmpty &&
            !after.startsWith(':') &&
            !after.startsWith('=') &&
            !RegExp(r'(?:[;|\t]|\s{2,})\s*$').hasMatch(before)) {
          continue;
        }
        yield (key: entry.key, start: match.start, end: match.end);
      }
    }
  }

  /// Exact parameter names understood for this field in this template.
  Set<String> labels(FieldDef field) => _labels(field);
}

Set<String> _labels(FieldDef field) {
  final Set<String> labels = <String>{
    field.label,
    field.fieldKey,
    if (field.outputColumn case final String column) column,
    ...?_parameterLabels[field.fieldKey],
  };
  final Object? custom = field.validation['ocr_aliases'];
  if (custom is List) {
    labels.addAll(<String>[
      for (final Object? label in custom)
        if (label is String && label.trim().isNotEmpty) label,
    ]);
  }
  if (field.unit case final String unit) {
    labels.add(
      field.label.replaceFirst(
        RegExp('\\s*\\(${RegExp.escape(unit)}\\)\\s*\$'),
        '',
      ),
    );
  }
  return labels;
}

RegExp _pattern(String name) {
  final String pattern = name
      .trim()
      .split(RegExp(r'[\s_/-]+'))
      .map(RegExp.escape)
      .join(r'[\s_/-]+');
  return RegExp(
    '(?<![\\p{L}\\p{N}])$pattern(?=\\s|[:=]|\$)',
    caseSensitive: false,
    unicode: true,
  );
}

// Stable field semantics supply familiar plate abbreviations. The profile
// checks all labels together so an abbreviation shared by two fields never
// resolves by field order, and custom templates can retain explicit aliases.
const Map<String, Set<String>> _parameterLabels = <String, Set<String>>{
  'serial_number': <String>{'Serial no.', 'Serial no', 'Serial', 'S/N', 'SN'},
  'model_number': <String>{'Model no.', 'Model no', 'Model'},
  'manufacturer_name': <String>{'Manufacturer', 'Mfr', 'Make'},
  'asset_number': <String>{'Asset no.', 'Asset no', 'Asset ID'},
  'asset_tag': <String>{'Asset tag', 'Tag no.'},
  'batch_number': <String>{'Batch no.', 'Batch no', 'Batch'},
  'lot_number': <String>{'Lot no.', 'Lot no', 'Lot'},
  'voltage': <String>{'Rated voltage', 'Voltage', 'Volt'},
  'frequency': <String>{'Rated frequency', 'Frequency', 'Freq'},
  'power': <String>{'Rated power', 'Power'},
  'expiry_date': <String>{'Expiry', 'Expires', 'EXP'},
  'manufacture_date': <String>{'Manufactured', 'Mfg date', 'MFD'},
};
