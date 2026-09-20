/// One column on a [TemplateDef], with every attribute of §12.2.
final class FieldDef {
  /// Creates a field. Requiredness is never a bool — a user may move the
  /// field between all three values (§13.2).
  const FieldDef({
    required this.fieldKey,
    required this.label,
    required this.type,
    this.requiredness = Requiredness.optional,
    this.defaultValue,
    this.unit,
    this.helpText,
    this.inputMode = InputMode.any,
    this.stickable = false,
    this.contextLevel,
    this.autoFill,
    this.refine = false,
    this.options = const <Object>[],
    this.group,
    this.outputColumn,
    this.requiredWhen,
    this.hidden = false,
    this.identity = false,
    this.validation = const <String, Object?>{},
    this.lookup = const <String, Object?>{},
    this.sortOrder = 0,
  });

  /// Stable key within the template. Never renamed once shipped.
  final String fieldKey;

  /// Operator-facing label, stored as user data.
  final String label;

  /// §12.1 type. Capture, review and export read behaviour from the registry.
  final FieldType type;

  /// REQUIRED, RECOMMENDED or OPTIONAL. The user's decision, never the app's.
  final Requiredness requiredness;

  /// Written when the operator leaves the field empty.
  final String? defaultValue;

  /// Displayed and exported unit, for example `L` or `kg`.
  final String? unit;

  /// One short line of guidance shown under the field (§12.2 `help`).
  final String? helpText;

  /// Who may fill the field.
  final InputMode inputMode;

  /// Whether this field may be pinned as context (§20).
  final bool stickable;

  /// Context hierarchy level when this field is a level of that hierarchy.
  final int? contextLevel;

  /// System fill source, or null when the field is not auto-filled.
  final AutoFill? autoFill;

  /// Store an AI-refined companion value beside the raw one (§32).
  final bool refine;

  /// Choice list, optionally with codes for export. Strings or `{code, label}`.
  final List<Object> options;

  /// Editor group this field sits in, when the template uses groups.
  final String? group;

  /// Spreadsheet column or generated header this field writes to.
  final String? outputColumn;

  /// Expression over other fields that makes this one required, when set.
  final String? requiredWhen;

  /// Kept out of capture and export; existing values are preserved (§18).
  final bool hidden;

  /// Participates in duplicate detection (§40).
  final bool identity;

  /// Pattern, length, range and custom message (§12.2 `validation`).
  final Map<String, Object?> validation;

  /// Reference-dataset binding (§16). Empty when the field is not a lookup.
  final Map<String, Object?> lookup;

  /// List order. Reads sort by this, then [label].
  final int sortOrder;

  /// Returns a copy with the provided fields replaced.
  FieldDef copyWith({
    String? fieldKey,
    String? label,
    FieldType? type,
    Requiredness? requiredness,
    String? defaultValue,
    String? unit,
    String? helpText,
    InputMode? inputMode,
    bool? stickable,
    int? contextLevel,
    AutoFill? autoFill,
    bool? refine,
    List<Object>? options,
    String? group,
    String? outputColumn,
    String? requiredWhen,
    bool? hidden,
    bool? identity,
    Map<String, Object?>? validation,
    Map<String, Object?>? lookup,
    int? sortOrder,
  }) {
    return FieldDef(
      fieldKey: fieldKey ?? this.fieldKey,
      label: label ?? this.label,
      type: type ?? this.type,
      requiredness: requiredness ?? this.requiredness,
      defaultValue: defaultValue ?? this.defaultValue,
      unit: unit ?? this.unit,
      helpText: helpText ?? this.helpText,
      inputMode: inputMode ?? this.inputMode,
      stickable: stickable ?? this.stickable,
      contextLevel: contextLevel ?? this.contextLevel,
      autoFill: autoFill ?? this.autoFill,
      refine: refine ?? this.refine,
      options: options ?? this.options,
      group: group ?? this.group,
      outputColumn: outputColumn ?? this.outputColumn,
      requiredWhen: requiredWhen ?? this.requiredWhen,
      hidden: hidden ?? this.hidden,
      identity: identity ?? this.identity,
      validation: validation ?? this.validation,
      lookup: lookup ?? this.lookup,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  int get hashCode => Object.hash(
    fieldKey,
    label,
    type,
    requiredness,
    defaultValue,
    unit,
    helpText,
    inputMode,
    stickable,
    contextLevel,
    autoFill,
    refine,
    Object.hashAll(options),
    group,
    outputColumn,
    requiredWhen,
    hidden,
    identity,
    Object.hash(
      Object.hashAll(
        validation.entries.map(
          (MapEntry<String, Object?> e) => Object.hash(e.key, e.value),
        ),
      ),
      Object.hashAll(
        lookup.entries.map(
          (MapEntry<String, Object?> e) => Object.hash(e.key, e.value),
        ),
      ),
      sortOrder,
    ),
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FieldDef &&
            other.fieldKey == fieldKey &&
            other.label == label &&
            other.type == type &&
            other.requiredness == requiredness &&
            other.defaultValue == defaultValue &&
            other.unit == unit &&
            other.helpText == helpText &&
            other.inputMode == inputMode &&
            other.stickable == stickable &&
            other.contextLevel == contextLevel &&
            other.autoFill == autoFill &&
            other.refine == refine &&
            _listEquals(other.options, options) &&
            other.group == group &&
            other.outputColumn == outputColumn &&
            other.requiredWhen == requiredWhen &&
            other.hidden == hidden &&
            other.identity == identity &&
            _mapEquals(other.validation, validation) &&
            _mapEquals(other.lookup, lookup) &&
            other.sortOrder == sortOrder);
  }
}

/// Three-value requiredness. Never a bool — a user may move a field
/// between all three (§13.2).
enum Requiredness {
  /// Blocks approval, not capture.
  required,

  /// Soft prompt at review, dismissible with a reason.
  recommended,

  /// No prompt. The shipped default for most columns.
  optional,
}

/// The nineteen field types of §12.1.
enum FieldType {
  /// Single line.
  text,

  /// Multi-line; refinement typically enabled.
  longText,

  /// Whole number, optional unit, min and max.
  number,

  /// Fractional number, optional unit, min and max.
  decimal,

  /// Amount whose currency code is per project.
  currency,

  /// Percentage.
  percentage,

  /// Calendar date. Auto-fill supported.
  date,

  /// Clock time. Auto-fill supported.
  time,

  /// Date and time. Auto-fill supported.
  dateTime,

  /// Switch.
  boolean,

  /// Single-select from [FieldDef.options].
  choice,

  /// Multi-select from [FieldDef.options].
  multiChoice,

  /// Bound to a reference dataset.
  lookup,

  /// Populated by the scanner, typeable as fallback.
  barcode,

  /// Names and paths of the record's photos.
  photoReference,

  /// Attached files.
  documentReference,

  /// Latitude, longitude and accuracy.
  gpsLocation,

  /// Drawn on screen, stored as an image.
  signature,

  /// Read-only expression over other fields.
  computed,
}

/// Who may write the field (§12.2 `input_mode`).
enum InputMode {
  /// Typing, AI, lookup or context may fill it.
  any,

  /// AI may never write it.
  manualOnly,

  /// AI may propose; a person confirms.
  aiAllowed,

  /// Filled by the system, read-only unless unlocked.
  auto,
}

/// System fill source (§12.2 `auto_fill`).
enum AutoFill {
  /// Current instant.
  now,

  /// Today's date.
  today,

  /// Current time of day.
  time,

  /// Next value in a sequence.
  sequence,

  /// Signed-in operator.
  operator,

  /// This device.
  device,

  /// Current GPS fix.
  gps,

  /// Pinned context value.
  context,
}

bool _listEquals(List<Object> left, List<Object> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index++) {
    if (!_valueEquals(left[index], right[index])) {
      return false;
    }
  }
  return true;
}

bool _mapEquals(Map<String, Object?> left, Map<String, Object?> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final MapEntry<String, Object?> entry in left.entries) {
    if (!right.containsKey(entry.key) ||
        !_valueEquals(entry.value, right[entry.key])) {
      return false;
    }
  }
  return true;
}

bool _valueEquals(Object? left, Object? right) {
  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }
    for (final MapEntry<dynamic, dynamic> entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !_valueEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }
    for (int index = 0; index < left.length; index++) {
      if (!_valueEquals(left[index], right[index])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}
