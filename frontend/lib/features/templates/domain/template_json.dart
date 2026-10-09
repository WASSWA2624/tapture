import 'dart:convert';

import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/reference/domain/domain.dart'
    show LookupBinding;

import 'field_def.dart';
import 'field_wire.dart';
import 'template_def.dart';
import 'template_row.dart';

/// Versioned JSON encoding of a [TemplateDef] for export and import.
abstract final class TemplateJson {
  /// Current payload version. An unknown value imports nothing.
  static const int schemaVersion = 1;

  /// Writes every §12.2 attribute, identity keys, rows and aliases.
  static Map<String, Object?> encode(TemplateDef template) {
    return <String, Object?>{
      _schemaVersionKey: schemaVersion,
      _templateKeyKey: template.templateKey,
      _nameKey: template.name,
      _kindKey: template.kind,
      _identityFieldsKey: List<String>.of(template.identityFieldKeys),
      _fieldsKey: <Map<String, Object?>>[
        for (final FieldDef field in template.fields) _encodeField(field),
      ],
      _rowsKey: <Map<String, Object?>>[
        for (final TemplateRow row in template.rows) _encodeRow(row),
      ],
      _sheetNameKey: template.sheetName,
      _headerRowKey: template.headerRow,
      _detectionKey: _withoutVersions(template.detection),
    };
  }

  /// Validates [raw] and returns a new project-owned template at version 1.
  ///
  /// [raw] is a JSON object or JSON text. Nothing is persisted here.
  static Result<TemplateDef> decode(Object? raw, {required String projectId}) {
    return _decode(raw, projectId: projectId, stored: false);
  }

  /// Reads an existing shape without activating unsupported source metadata.
  /// Structural validation remains identical to strict import decoding.
  static Result<TemplateDef> decodeStoredShape(
    Object? raw, {
    required String projectId,
  }) => _decode(raw, projectId: projectId, stored: true);
}

Result<TemplateDef> _decode(
  Object? raw, {
  required String projectId,
  required bool stored,
}) {
  final Object? json = _parsed(raw);
  if (json is! Map) {
    return FailureResult<TemplateDef>(_invalid);
  }
  return _decodeMap(_stringMap(json), projectId: projectId, stored: stored);
}

Map<String, Object?> _encodeField(FieldDef field) {
  return <String, Object?>{
    _fieldKeyKey: field.fieldKey,
    _labelKey: field.label,
    _typeKey: FieldWire.fieldTypeToWire(field.type),
    _requiredKey: _requirednessToWire(field.requiredness),
    _defaultKey: field.defaultValue,
    _unitKey: field.unit,
    _helpKey: field.helpText,
    _inputModeKey: FieldWire.inputModeToWire(field.inputMode),
    _stickableKey: field.stickable,
    _contextLevelKey: field.contextLevel,
    _autoFillKey: field.autoFill == null
        ? _carriedSource(field.validation)
        : _autoFillToWire(field.autoFill!),
    _refineKey: field.refine,
    _optionsKey: field.options,
    _groupKey: field.group,
    _outputColumnKey: field.outputColumn,
    _requiredWhenKey: field.requiredWhen,
    _hiddenKey: field.hidden,
    _identityKey: field.identity,
    _validationKey: Map<String, Object?>.of(field.validation),
    _lookupKey: Map<String, Object?>.of(field.lookup),
    _sortOrderKey: field.sortOrder,
  };
}

Map<String, Object?> _encodeRow(TemplateRow row) {
  return <String, Object?>{
    _identifierKey: row.identifier,
    _labelKey: row.label,
    _outputRowKey: row.outputRowNumber,
    _aliasesKey: List<String>.of(row.aliases),
    _metadataKey: Map<String, Object?>.of(row.metadata),
    _foundStatusKey: row.foundStatus,
  };
}

Result<TemplateDef> _decodeMap(
  Map<String, Object?> map, {
  required String projectId,
  required bool stored,
}) {
  final Object? version = map[_schemaVersionKey];
  if (version is! int || version != TemplateJson.schemaVersion) {
    return FailureResult<TemplateDef>(_unknownSchema);
  }
  final String? name = _text(map[_nameKey]);
  if (name == null) {
    return FailureResult<TemplateDef>(_invalid);
  }
  final Result<List<FieldDef>> fields = _fieldsOf(
    map[_fieldsKey],
    stored: stored,
  );
  if (fields is FailureResult<List<FieldDef>>) {
    return FailureResult<TemplateDef>(fields.failure);
  }
  final Result<List<TemplateRow>> rows = _rowsOf(map[_rowsKey]);
  if (rows is FailureResult<List<TemplateRow>>) {
    return FailureResult<TemplateDef>(rows.failure);
  }
  final Result<List<String>> identity = _stringListOf(map[_identityFieldsKey]);
  if (identity is FailureResult<List<String>>) {
    return FailureResult<TemplateDef>(identity.failure);
  }
  final Result<int?> headerRow = _optionalInt(map[_headerRowKey]);
  if (headerRow is FailureResult<int?>) {
    return FailureResult<TemplateDef>(headerRow.failure);
  }
  final Result<Map<String, Object?>> detection = _objectMapOf(
    map[_detectionKey],
  );
  if (detection is FailureResult<Map<String, Object?>>) {
    return FailureResult<TemplateDef>(detection.failure);
  }
  final List<FieldDef> decodedFields = fields.getOrElse(
    () => const <FieldDef>[],
  );
  final String? unbindable = _lookupProblem(decodedFields);
  if (unbindable != null) {
    return FailureResult<TemplateDef>(
      ValidationFailure(
        message: unbindable,
        localizedRecovery: DomainCopy.messages.lookupImportRecovery,
      ),
    );
  }
  List<String> identityKeys = identity.getOrElse(() => const <String>[]);
  if (identityKeys.isEmpty) {
    identityKeys = <String>[
      for (final FieldDef field in decodedFields)
        if (field.identity) field.fieldKey,
    ];
  }
  return Success<TemplateDef>(
    TemplateDef(
      id: '',
      templateKey: _text(map[_templateKeyKey]) ?? '',
      name: name,
      version: 1,
      fields: <FieldDef>[
        for (final FieldDef field in decodedFields)
          field.copyWith(identity: identityKeys.contains(field.fieldKey)),
      ],
      identityFieldKeys: identityKeys,
      rows: rows.getOrElse(() => const <TemplateRow>[]),
      projectId: projectId,
      kind: _text(map[_kindKey]) ?? '',
      source: _importedSource,
      sheetName: _text(map[_sheetNameKey]),
      headerRow: headerRow.getOrElse(() => null),
      detection: _withoutVersions(
        detection.getOrElse(() => const <String, Object?>{}),
      ),
    ),
  );
}

/// Why a field's lookup cannot be accepted: it fills a field the template
/// does not define, or fills one field twice (task 010 step 6). Null when
/// every binding holds.
String? _lookupProblem(List<FieldDef> fields) {
  final Set<String> keys = <String>{
    for (final FieldDef field in fields) field.fieldKey,
  };
  for (final FieldDef field in fields) {
    final LookupBinding? binding = LookupBinding.fromMap(field.lookup);
    if (binding == null) {
      continue;
    }
    final String? problem = LookupBinding.validate(
      binding: binding,
      templateFieldKeys: keys,
    );
    if (problem != null) {
      return problem;
    }
  }
  return null;
}

Result<List<FieldDef>> _fieldsOf(Object? raw, {required bool stored}) {
  if (raw == null) {
    return const Success<List<FieldDef>>(<FieldDef>[]);
  }
  if (raw is! List) {
    return FailureResult<List<FieldDef>>(_invalid);
  }
  final List<FieldDef> fields = <FieldDef>[];
  final Set<String> seen = <String>{};
  for (int index = 0; index < raw.length; index++) {
    final Result<FieldDef> field = _fieldOf(
      raw[index],
      index: index,
      seen: seen,
      stored: stored,
    );
    switch (field) {
      case FailureResult<FieldDef>(:final Failure failure):
        return FailureResult<List<FieldDef>>(failure);
      case Success<FieldDef>(:final FieldDef value):
        seen.add(value.fieldKey);
        fields.add(value);
    }
  }
  return Success<List<FieldDef>>(fields);
}

Result<FieldDef> _fieldOf(
  Object? raw, {
  required int index,
  required Set<String> seen,
  required bool stored,
}) {
  if (raw is! Map) {
    return FailureResult<FieldDef>(_invalid);
  }
  final Map<String, Object?> map = _stringMap(raw);
  final String? fieldKey = _text(map[_fieldKeyKey]);
  final String? typeName = _text(map[_typeKey]);
  if (fieldKey == null || typeName == null) {
    return FailureResult<FieldDef>(_invalid);
  }
  if (seen.contains(fieldKey)) {
    return FailureResult<FieldDef>(_duplicateField);
  }
  final FieldType? type = _typeOf(typeName);
  if (type == null) {
    return FailureResult<FieldDef>(_invalid);
  }
  final Requiredness? requiredness = _requirednessOf(map[_requiredKey]);
  if (requiredness == null) {
    return FailureResult<FieldDef>(_invalid);
  }
  final InputMode? inputMode = _inputModeOf(map[_inputModeKey]);
  if (inputMode == null) {
    return FailureResult<FieldDef>(_invalid);
  }
  final bool? stickable = _flag(map[_stickableKey], fallback: false);
  final bool? refine = _flag(map[_refineKey], fallback: false);
  final bool? hidden = _flag(map[_hiddenKey], fallback: false);
  final bool? identity = _flag(map[_identityKey], fallback: false);
  if (stickable == null ||
      refine == null ||
      hidden == null ||
      identity == null) {
    return FailureResult<FieldDef>(_invalid);
  }
  final Result<int?> contextLevel = _optionalInt(map[_contextLevelKey]);
  if (contextLevel is FailureResult<int?>) {
    return FailureResult<FieldDef>(contextLevel.failure);
  }
  final Result<int?> sortOrder = _optionalInt(map[_sortOrderKey]);
  if (sortOrder is FailureResult<int?>) {
    return FailureResult<FieldDef>(sortOrder.failure);
  }
  final Result<List<Object>> options = _optionsOf(map[_optionsKey]);
  if (options is FailureResult<List<Object>>) {
    return FailureResult<FieldDef>(options.failure);
  }
  final Result<Map<String, Object?>> validation = _objectMapOf(
    map[_validationKey],
  );
  if (validation is FailureResult<Map<String, Object?>>) {
    return FailureResult<FieldDef>(validation.failure);
  }
  final Map<String, Object?> rules = Map<String, Object?>.of(
    validation.getOrElse(() => const <String, Object?>{}),
  );
  final Object? carried = _carriedSource(rules);
  AutoFill? source;
  Object? unavailable;
  for (final Object? declaration in <Object?>[map[_autoFillKey], carried]) {
    if (declaration == null) continue;
    final Result<AutoFill?> parsed = _autoFillOf(declaration);
    final AutoFill? known = parsed.getOrElse(() => null);
    final bool needsText =
        known == AutoFill.localAddress && type != FieldType.text;
    if (parsed is FailureResult<AutoFill?> || needsText) {
      if (!stored) {
        return FailureResult<FieldDef>(
          needsText ? _addressNeedsText : _invalid,
        );
      }
      unavailable ??= declaration;
    } else {
      source ??= known;
    }
  }
  final Object? oldAttrs = rules[_attrsKey];
  final Map<String, Object?> attrs = oldAttrs is Map
      ? _stringMap(oldAttrs)
      : <String, Object?>{};
  attrs.remove(_storedAutoFillKey);
  if (unavailable != null) {
    attrs[_storedAutoFillKey] = unavailable;
    source = null;
  }
  if (attrs.isEmpty) {
    rules.remove(_attrsKey);
  } else {
    rules[_attrsKey] = attrs;
  }
  final Result<Map<String, Object?>> lookup = _objectMapOf(map[_lookupKey]);
  if (lookup is FailureResult<Map<String, Object?>>) {
    return FailureResult<FieldDef>(lookup.failure);
  }
  return Success<FieldDef>(
    FieldDef(
      fieldKey: fieldKey,
      label: _text(map[_labelKey]) ?? '',
      type: type,
      requiredness: requiredness,
      defaultValue: _text(map[_defaultKey]),
      unit: _text(map[_unitKey]),
      helpText: _text(map[_helpKey]),
      inputMode: inputMode,
      stickable: stickable,
      contextLevel: contextLevel.getOrElse(() => null),
      autoFill: source,
      refine: refine,
      options: options.getOrElse(() => const <Object>[]),
      group: _text(map[_groupKey]),
      outputColumn: _text(map[_outputColumnKey]),
      requiredWhen: _text(map[_requiredWhenKey]),
      hidden: hidden,
      identity: identity,
      validation: rules,
      lookup: lookup.getOrElse(() => const <String, Object?>{}),
      sortOrder: sortOrder.getOrElse(() => null) ?? index,
    ),
  );
}

Result<List<TemplateRow>> _rowsOf(Object? raw) {
  if (raw == null) {
    return const Success<List<TemplateRow>>(<TemplateRow>[]);
  }
  if (raw is! List) {
    return FailureResult<List<TemplateRow>>(_invalid);
  }
  final List<TemplateRow> rows = <TemplateRow>[];
  for (final Object? item in raw) {
    final Result<TemplateRow> row = _rowOf(item);
    switch (row) {
      case FailureResult<TemplateRow>(:final Failure failure):
        return FailureResult<List<TemplateRow>>(failure);
      case Success<TemplateRow>(:final TemplateRow value):
        rows.add(value);
    }
  }
  return Success<List<TemplateRow>>(rows);
}

Result<TemplateRow> _rowOf(Object? raw) {
  if (raw is! Map) {
    return FailureResult<TemplateRow>(_invalid);
  }
  final Map<String, Object?> map = _stringMap(raw);
  final String? identifier = _text(map[_identifierKey]);
  final Result<int?> outputRow = _optionalInt(map[_outputRowKey]);
  if (identifier == null || outputRow is FailureResult<int?>) {
    return FailureResult<TemplateRow>(_invalid);
  }
  final int? outputRowNumber = outputRow.getOrElse(() => null);
  if (outputRowNumber == null) {
    return FailureResult<TemplateRow>(_invalid);
  }
  final Result<List<String>> aliases = _stringListOf(map[_aliasesKey]);
  if (aliases is FailureResult<List<String>>) {
    return FailureResult<TemplateRow>(aliases.failure);
  }
  final Result<Map<String, Object?>> metadata = _objectMapOf(map[_metadataKey]);
  if (metadata is FailureResult<Map<String, Object?>>) {
    return FailureResult<TemplateRow>(metadata.failure);
  }
  return Success<TemplateRow>(
    TemplateRow(
      identifier: identifier,
      label: _text(map[_labelKey]) ?? '',
      outputRowNumber: outputRowNumber,
      aliases: aliases.getOrElse(() => const <String>[]),
      metadata: metadata.getOrElse(() => const <String, Object?>{}),
      foundStatus: _text(map[_foundStatusKey]) ?? 'missing',
    ),
  );
}

Result<List<String>> _stringListOf(Object? raw) {
  if (raw == null) {
    return const Success<List<String>>(<String>[]);
  }
  if (raw is! List) {
    return FailureResult<List<String>>(_invalid);
  }
  final List<String> values = <String>[];
  for (final Object? item in raw) {
    final String? text = _text(item);
    if (text == null) {
      return FailureResult<List<String>>(_invalid);
    }
    values.add(text);
  }
  return Success<List<String>>(values);
}

Result<List<Object>> _optionsOf(Object? raw) {
  if (raw == null) {
    return const Success<List<Object>>(<Object>[]);
  }
  if (raw is! List) {
    return FailureResult<List<Object>>(_invalid);
  }
  return Success<List<Object>>(<Object>[
    for (final Object? item in raw)
      if (item != null) _canonical(item),
  ]);
}

Result<Map<String, Object?>> _objectMapOf(Object? raw) {
  if (raw == null) {
    return const Success<Map<String, Object?>>(<String, Object?>{});
  }
  if (raw is! Map) {
    return FailureResult<Map<String, Object?>>(_invalid);
  }
  return Success<Map<String, Object?>>(_stringMap(raw));
}

Result<int?> _optionalInt(Object? raw) {
  if (raw == null) {
    return const Success<int?>(null);
  }
  final int? value = _asInt(raw);
  if (value == null) {
    return FailureResult<int?>(_invalid);
  }
  return Success<int?>(value);
}

Result<AutoFill?> _autoFillOf(Object? raw) {
  if (raw == null) {
    return const Success<AutoFill?>(null);
  }
  if (raw is! String) {
    return FailureResult<AutoFill?>(_invalid);
  }
  final AutoFill? value = _autoFillFromWire(raw);
  if (value == null) {
    return FailureResult<AutoFill?>(_invalid);
  }
  return Success<AutoFill?>(value);
}

Object? _carriedSource(Map<String, Object?> validation) {
  final Object? attrs = validation[_attrsKey];
  return attrs is Map ? attrs[_storedAutoFillKey] : null;
}

Object? _parsed(Object? raw) {
  if (raw is String) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
  return raw;
}

Map<String, Object?> _stringMap(Map<dynamic, dynamic> raw) {
  return <String, Object?>{
    for (final MapEntry<dynamic, dynamic> entry in raw.entries)
      if (entry.key is String)
        entry.key as String: _canonicalNullable(entry.value),
  };
}

Map<String, Object?> _withoutVersions(Map<String, Object?> raw) {
  return <String, Object?>{
    for (final MapEntry<String, Object?> entry in raw.entries)
      if (entry.key != _versionsKey) entry.key: entry.value,
  };
}

Object _canonical(Object value) {
  if (value is Map) {
    return _stringMap(value);
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

String? _text(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  return null;
}

int? _asInt(Object? raw) {
  if (raw is int) {
    return raw;
  }
  if (raw is double && raw == raw.truncateToDouble()) {
    return raw.toInt();
  }
  return null;
}

bool? _flag(Object? raw, {required bool fallback}) {
  if (raw == null) {
    return fallback;
  }
  if (raw is bool) {
    return raw;
  }
  return null;
}

FieldType? _typeOf(String raw) {
  try {
    return FieldWire.fieldTypeFromWire(raw);
  } on Failure {
    return null;
  }
}

InputMode? _inputModeOf(Object? raw) {
  if (raw == null) {
    return InputMode.any;
  }
  if (raw is! String) {
    return null;
  }
  try {
    return FieldWire.inputModeFromWire(raw);
  } on Failure {
    return null;
  }
}

String _requirednessToWire(Requiredness value) {
  return switch (value) {
    Requiredness.required => 'REQUIRED',
    Requiredness.recommended => 'RECOMMENDED',
    Requiredness.optional => 'OPTIONAL',
  };
}

Requiredness? _requirednessOf(Object? raw) {
  if (raw == null) {
    return Requiredness.optional;
  }
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
    AutoFill.localAddress => 'LOCAL_ADDRESS',
  };
}

AutoFill? _autoFillFromWire(String raw) {
  return switch (raw.trim().toUpperCase()) {
    'NOW' => AutoFill.now,
    'TODAY' => AutoFill.today,
    'TIME' => AutoFill.time,
    'SEQUENCE' => AutoFill.sequence,
    'OPERATOR' => AutoFill.operator,
    'DEVICE' => AutoFill.device,
    'GPS' => AutoFill.gps,
    'CONTEXT' => AutoFill.context,
    'LOCAL_ADDRESS' => AutoFill.localAddress,
    _ => null,
  };
}

const String _importedSource = 'imported';
const String _schemaVersionKey = 'schema_version';
const String _templateKeyKey = 'template_key';
const String _nameKey = 'name';
const String _kindKey = 'kind';
const String _identityFieldsKey = 'identity_fields';
const String _fieldsKey = 'fields';
const String _rowsKey = 'rows';
const String _sheetNameKey = 'sheet_name';
const String _headerRowKey = 'header_row';
const String _detectionKey = 'detection';
const String _fieldKeyKey = 'field_key';
const String _labelKey = 'label';
const String _typeKey = 'type';
const String _requiredKey = 'required';
const String _defaultKey = 'default';
const String _unitKey = 'unit';
const String _helpKey = 'help';
const String _inputModeKey = 'input_mode';
const String _stickableKey = 'stickable';
const String _contextLevelKey = 'context_level';
const String _autoFillKey = 'auto_fill';
const String _refineKey = 'refine';
const String _optionsKey = 'options';
const String _groupKey = 'group';
const String _outputColumnKey = 'output_column';
const String _requiredWhenKey = 'required_when';
const String _hiddenKey = 'hidden';
const String _identityKey = 'identity';
const String _validationKey = 'validation';
const String _lookupKey = 'lookup';
const String _sortOrderKey = 'sort_order';
const String _identifierKey = 'identifier';
const String _outputRowKey = 'output_row';
const String _aliasesKey = 'aliases';
const String _metadataKey = 'metadata';
const String _foundStatusKey = 'found_status';
const String _versionsKey = '_tapture_versions';
const String _attrsKey = '_tapture';
const String _storedAutoFillKey = 'autoFill';

final ValidationFailure _addressNeedsText = ValidationFailure(
  localizedMessage: DomainCopy.messages.fieldSourceAddressNeedsText,
  localizedRecovery: DomainCopy.messages.templatesImportInvalidRecovery,
);

final ValidationFailure _unknownSchema = ValidationFailure(
  localizedMessage: DomainCopy.messages.templatesImportUnknownSchema,
  localizedRecovery: DomainCopy.messages.templatesImportUnknownSchemaRecovery,
);

final ValidationFailure _invalid = ValidationFailure(
  localizedMessage: DomainCopy.messages.templatesImportInvalid,
  localizedRecovery: DomainCopy.messages.templatesImportInvalidRecovery,
);

final ValidationFailure _duplicateField = ValidationFailure(
  localizedMessage: DomainCopy.messages.templatesImportDuplicateField,
  localizedRecovery: DomainCopy.messages.templatesImportDuplicateFieldRecovery,
);
