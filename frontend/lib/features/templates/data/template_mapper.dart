import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/errors/failure.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_row.dart';

/// Maps Drift template rows onto [TemplateDef] / [FieldDef] / [TemplateRow]
/// and back.
///
/// Presentation never sees a database type; only
/// [TemplateRepositoryImpl] and this mapper import both layers.
/// An attribute the table stores and the model drops is a defect the
/// round-trip test catches.
abstract final class TemplateMapper {
  /// Reads a stored header plus its fields and rows.
  static TemplateDef fromRows({
    required sqlite.Template header,
    required List<sqlite.TemplateField> fields,
    required List<sqlite.TemplateRow> rows,
  }) {
    final ({String templateKey, Map<String, Object?> detection}) detection =
        _detectionOf(header.detection);
    final List<String> identityKeys = _stringList(header.identityFields);
    return TemplateDef(
      id: header.id,
      templateKey: detection.templateKey,
      name: header.name,
      version: header.version,
      fields: <FieldDef>[
        for (final sqlite.TemplateField field in fields)
          fieldFromRow(field, identityKeys: identityKeys),
      ],
      identityFieldKeys: identityKeys,
      rows: <TemplateRow>[
        for (final sqlite.TemplateRow row in rows) rowFromRow(row),
      ],
      projectId: header.projectId,
      kind: header.kind,
      source: header.source,
      sourceFilePath: _optionalText(header.sourceFilePath),
      sheetName: _optionalText(header.sheetName),
      headerRow: header.headerRow,
      detection: detection.detection,
    );
  }

  /// Writes [template] as an insertable header. [TemplateDef.templateKey]
  /// is stored inside the detection JSON so the table stays as 053 left it.
  static sqlite.TemplatesCompanion headerToRow(TemplateDef template) {
    return sqlite.TemplatesCompanion(
      id: template.id.isEmpty
          ? const Value<String>.absent()
          : Value<String>(template.id),
      projectId: Value<String?>(template.projectId),
      name: Value<String>(template.name),
      kind: Value<String>(template.kind),
      source: Value<String>(template.source),
      sourceFilePath: Value<String?>(template.sourceFilePath),
      sheetName: Value<String?>(template.sheetName),
      headerRow: Value<int?>(template.headerRow),
      identityFields: Value<String>(jsonEncode(template.identityFieldKeys)),
      detection: Value<String>(_encodeDetection(template)),
      version: Value<int>(template.version < 1 ? 1 : template.version),
    );
  }

  /// Reads one stored field. Attributes the table has no column for live in
  /// the validation JSON under [_attrsKey].
  static FieldDef fieldFromRow(
    sqlite.TemplateField row, {
    Iterable<String> identityKeys = const <String>[],
  }) {
    final ({Map<String, Object?> validation, Map<String, Object?> attrs})
    stored = _validationOf(row.validation);
    final Map<String, Object?> attrs = stored.attrs;
    final Requiredness requiredness =
        _requirednessFromWire(attrs[_requirednessKey]) ??
        (row.isRequired ? Requiredness.required : Requiredness.optional);
    final AutoFill? autoFill =
        _autoFillFromWire(attrs[_autoFillKey]) ??
        (row.autoFill ? AutoFill.context : null);
    return FieldDef(
      fieldKey: row.fieldKey,
      label: row.label,
      type: fieldTypeFromWire(row.type),
      requiredness: requiredness,
      defaultValue: _optionalText(row.defaultValue),
      unit: _optionalText(row.unit),
      helpText: _optionalText(attrs[_helpTextKey]),
      inputMode: inputModeFromWire(row.inputMode),
      stickable: row.stickable,
      contextLevel: row.contextLevel,
      autoFill: autoFill,
      refine: row.refine,
      options: _decodeOptions(row.options),
      group: _optionalText(attrs[_groupKey]),
      outputColumn: _optionalText(row.outputColumn),
      requiredWhen: _optionalText(attrs[_requiredWhenKey]),
      hidden: attrs[_hiddenKey] == true,
      identity:
          attrs[_identityKey] == true || identityKeys.contains(row.fieldKey),
      validation: stored.validation,
      lookup: _objectMap(row.lookup),
      sortOrder: row.sortOrder,
    );
  }

  /// Writes [field] as an insertable row. [id] is the stored merge id when
  /// this [FieldDef.fieldKey] already exists on [templateId].
  static sqlite.TemplateFieldsCompanion fieldToRow(
    FieldDef field, {
    required String templateId,
    String? id,
    int? sortOrder,
  }) {
    return sqlite.TemplateFieldsCompanion(
      id: id == null || id.isEmpty
          ? const Value<String>.absent()
          : Value<String>(id),
      templateId: Value<String>(templateId),
      fieldKey: Value<String>(field.fieldKey),
      label: Value<String>(field.label),
      type: Value<String>(fieldTypeToWire(field.type)),
      outputColumn: Value<String?>(field.outputColumn),
      isRequired: Value<bool>(field.requiredness == Requiredness.required),
      inputMode: Value<String>(inputModeToWire(field.inputMode)),
      stickable: Value<bool>(field.stickable),
      contextLevel: Value<int?>(field.contextLevel),
      autoFill: Value<bool>(field.autoFill != null),
      defaultValue: Value<String?>(field.defaultValue),
      options: Value<String>(jsonEncode(field.options)),
      unit: Value<String?>(field.unit),
      validation: Value<String>(_encodeValidation(field)),
      lookup: Value<String>(jsonEncode(field.lookup)),
      refine: Value<bool>(field.refine),
      sortOrder: Value<int>(sortOrder ?? field.sortOrder),
    );
  }

  /// Reads one stored checklist row.
  static TemplateRow rowFromRow(sqlite.TemplateRow row) {
    return TemplateRow(
      identifier: row.identifier,
      label: row.label,
      outputRowNumber: row.outputRowNumber,
      aliases: _stringList(row.aliases),
      metadata: _objectMap(row.metadata),
      foundStatus: row.foundStatus,
    );
  }

  /// Writes [row] as an insertable checklist row.
  static sqlite.TemplateRowsCompanion rowToRow(
    TemplateRow row, {
    required String templateId,
    String? id,
  }) {
    return sqlite.TemplateRowsCompanion(
      id: id == null || id.isEmpty
          ? const Value<String>.absent()
          : Value<String>(id),
      templateId: Value<String>(templateId),
      outputRowNumber: Value<int>(row.outputRowNumber),
      identifier: Value<String>(row.identifier),
      label: Value<String>(row.label),
      aliases: Value<String>(jsonEncode(row.aliases)),
      metadata: Value<String>(jsonEncode(row.metadata)),
      foundStatus: Value<String>(row.foundStatus),
    );
  }

  /// Wire name stored in the type column.
  static String fieldTypeToWire(FieldType type) {
    return switch (type) {
      FieldType.text => 'text',
      FieldType.longText => 'long_text',
      FieldType.number => 'number',
      FieldType.decimal => 'decimal',
      FieldType.currency => 'currency',
      FieldType.percentage => 'percentage',
      FieldType.date => 'date',
      FieldType.time => 'time',
      FieldType.dateTime => 'date_time',
      FieldType.boolean => 'boolean',
      FieldType.choice => 'choice',
      FieldType.multiChoice => 'multi_choice',
      FieldType.lookup => 'lookup',
      FieldType.barcode => 'barcode',
      FieldType.photoReference => 'photo_reference',
      FieldType.documentReference => 'document_reference',
      FieldType.gpsLocation => 'gps_location',
      FieldType.signature => 'signature',
      FieldType.computed => 'computed',
    };
  }

  /// Reads a stored type name. An unknown name is a defect.
  static FieldType fieldTypeFromWire(String raw) {
    return switch (raw.trim()) {
      '' || 'text' => FieldType.text,
      'long_text' || 'longText' || 'long text' => FieldType.longText,
      'number' => FieldType.number,
      'decimal' => FieldType.decimal,
      'currency' => FieldType.currency,
      'percentage' => FieldType.percentage,
      'date' => FieldType.date,
      'time' => FieldType.time,
      'date_time' || 'dateTime' || 'date-time' => FieldType.dateTime,
      'boolean' => FieldType.boolean,
      'choice' => FieldType.choice,
      'multi_choice' ||
      'multiChoice' ||
      'multi-choice' => FieldType.multiChoice,
      'lookup' => FieldType.lookup,
      'barcode' => FieldType.barcode,
      'photo_reference' || 'photoReference' => FieldType.photoReference,
      'document_reference' ||
      'documentReference' => FieldType.documentReference,
      'gps_location' ||
      'gpsLocation' ||
      'GPS location' => FieldType.gpsLocation,
      'signature' => FieldType.signature,
      'computed' => FieldType.computed,
      _ => throw const StorageFailure(
        message: 'That field type is not recognised.',
        recoveryAction: 'Pick a type from the list and save again.',
      ),
    };
  }

  /// Wire name stored in the input-mode column.
  static String inputModeToWire(InputMode mode) {
    return switch (mode) {
      InputMode.any => 'ANY',
      InputMode.manualOnly => 'MANUAL_ONLY',
      InputMode.aiAllowed => 'AI_ALLOWED',
      InputMode.auto => 'AUTO',
    };
  }

  /// Reads a stored input mode. Empty is [InputMode.any].
  static InputMode inputModeFromWire(String raw) {
    return switch (raw.trim().toUpperCase()) {
      '' || 'ANY' => InputMode.any,
      'MANUAL_ONLY' => InputMode.manualOnly,
      'AI_ALLOWED' => InputMode.aiAllowed,
      'AUTO' => InputMode.auto,
      _ => throw const StorageFailure(
        message: 'That input mode is not recognised.',
        recoveryAction: 'Pick an input mode from the list and save again.',
      ),
    };
  }
}

const String _templateKeyKey = 'template_key';
const String _attrsKey = '_tapture';
const String _helpTextKey = 'helpText';
const String _requiredWhenKey = 'requiredWhen';
const String _hiddenKey = 'hidden';
const String _groupKey = 'group';
const String _identityKey = 'identity';
const String _requirednessKey = 'requiredness';
const String _autoFillKey = 'autoFill';

({String templateKey, Map<String, Object?> detection}) _detectionOf(
  String raw,
) {
  final Map<String, Object?> detection = _objectMap(raw);
  final String templateKey =
      _optionalText(detection.remove(_templateKeyKey)) ?? '';
  return (templateKey: templateKey, detection: detection);
}

String _encodeDetection(TemplateDef template) {
  final Map<String, Object?> json = Map<String, Object?>.of(template.detection);
  final String key = template.templateKey.trim();
  if (key.isEmpty) {
    json.remove(_templateKeyKey);
  } else {
    json[_templateKeyKey] = key;
  }
  return jsonEncode(json);
}

({Map<String, Object?> validation, Map<String, Object?> attrs}) _validationOf(
  String raw,
) {
  final Map<String, Object?> json = _objectMap(raw);
  final Object? rawAttrs = json.remove(_attrsKey);
  final Map<String, Object?> attrs = rawAttrs is Map
      ? _asStringMap(rawAttrs)
      : <String, Object?>{};
  return (validation: json, attrs: attrs);
}

String _encodeValidation(FieldDef field) {
  final Map<String, Object?> json = Map<String, Object?>.of(field.validation);
  final Map<String, Object?> attrs = <String, Object?>{};
  final String? helpText = _optionalText(field.helpText);
  if (helpText != null) {
    attrs[_helpTextKey] = helpText;
  }
  final String? requiredWhen = _optionalText(field.requiredWhen);
  if (requiredWhen != null) {
    attrs[_requiredWhenKey] = requiredWhen;
  }
  if (field.hidden) {
    attrs[_hiddenKey] = true;
  }
  final String? group = _optionalText(field.group);
  if (group != null) {
    attrs[_groupKey] = group;
  }
  if (field.identity) {
    attrs[_identityKey] = true;
  }
  if (field.requiredness != Requiredness.optional) {
    attrs[_requirednessKey] = _requirednessToWire(field.requiredness);
  }
  if (field.autoFill != null) {
    attrs[_autoFillKey] = _autoFillToWire(field.autoFill!);
  }
  if (attrs.isEmpty) {
    json.remove(_attrsKey);
  } else {
    json[_attrsKey] = attrs;
  }
  return jsonEncode(json);
}

String _requirednessToWire(Requiredness value) {
  return switch (value) {
    Requiredness.required => 'REQUIRED',
    Requiredness.recommended => 'RECOMMENDED',
    Requiredness.optional => 'OPTIONAL',
  };
}

Requiredness? _requirednessFromWire(Object? raw) {
  if (raw is! String) {
    return null;
  }
  return switch (raw.trim().toUpperCase()) {
    'REQUIRED' => Requiredness.required,
    'RECOMMENDED' => Requiredness.recommended,
    'OPTIONAL' => Requiredness.optional,
    _ => null,
  };
}

String _autoFillToWire(AutoFill value) {
  return switch (value) {
    AutoFill.now => 'NOW',
    AutoFill.today => 'TODAY',
    AutoFill.time => 'TIME',
    AutoFill.sequence => 'SEQUENCE',
    AutoFill.operator => 'OPERATOR',
    AutoFill.device => 'DEVICE',
    AutoFill.gps => 'GPS',
    AutoFill.context => 'CONTEXT',
  };
}

AutoFill? _autoFillFromWire(Object? raw) {
  if (raw is! String) {
    return null;
  }
  return switch (raw.trim().toUpperCase()) {
    'NOW' => AutoFill.now,
    'TODAY' => AutoFill.today,
    'TIME' => AutoFill.time,
    'SEQUENCE' => AutoFill.sequence,
    'OPERATOR' => AutoFill.operator,
    'DEVICE' => AutoFill.device,
    'GPS' => AutoFill.gps,
    'CONTEXT' => AutoFill.context,
    _ => null,
  };
}

List<Object> _decodeOptions(String raw) {
  final Object? decoded = _decodeJson(raw);
  if (decoded is List) {
    return <Object>[
      for (final Object? item in decoded)
        if (item != null) _canonical(item),
    ];
  }
  if (decoded is Map) {
    return <Object>[_asStringMap(decoded)];
  }
  return const <Object>[];
}

List<String> _stringList(String raw) {
  final Object? decoded = _decodeJson(raw);
  if (decoded is! List) {
    return const <String>[];
  }
  return <String>[
    for (final Object? item in decoded)
      if (item is String && item.trim().isNotEmpty) item,
  ];
}

Map<String, Object?> _objectMap(String raw) {
  final Object? decoded = _decodeJson(raw);
  if (decoded is Map) {
    return _asStringMap(decoded);
  }
  return <String, Object?>{};
}

Map<String, Object?> _asStringMap(Map<dynamic, dynamic> raw) {
  return <String, Object?>{
    for (final MapEntry<dynamic, dynamic> entry in raw.entries)
      if (entry.key is String)
        entry.key as String: _canonicalNullable(entry.value),
  };
}

Object _canonical(Object value) {
  if (value is Map) {
    return _asStringMap(value);
  }
  if (value is List) {
    return <Object>[
      for (final Object? item in value)
        if (item != null) _canonical(item),
    ];
  }
  return value;
}

Object? _canonicalNullable(Object? value) {
  if (value == null) {
    return null;
  }
  return _canonical(value);
}

Object? _decodeJson(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

String? _optionalText(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  return null;
}
