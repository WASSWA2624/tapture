/// One value written onto a record for a field. Lives here until the records
/// feature owns the domain type; core cannot import features (FE-STR-04).
final class FieldValue {
  /// Creates a value. [audit] is append-only history of corrections.
  const FieldValue({
    required this.fieldKey,
    this.value,
    this.source = ValueSource.manual,
    this.verified = false,
    this.audit = const <FieldAudit>[],
  });

  /// Template field this value fills.
  final String fieldKey;

  /// Current stored value, after the type's normaliser.
  final Object? value;

  /// Where the current value came from. An edit becomes [ValueSource.manual].
  final ValueSource source;

  /// Whether an operator has confirmed the current value.
  final bool verified;

  /// Every correction, including a change back to the original (FE-SEC-09).
  final List<FieldAudit> audit;

  /// Returns a copy with the provided fields replaced.
  FieldValue copyWith({
    String? fieldKey,
    Object? value,
    ValueSource? source,
    bool? verified,
    List<FieldAudit>? audit,
    bool clearValue = false,
  }) {
    return FieldValue(
      fieldKey: fieldKey ?? this.fieldKey,
      value: clearValue ? null : (value ?? this.value),
      source: source ?? this.source,
      verified: verified ?? this.verified,
      audit: audit ?? this.audit,
    );
  }

  @override
  int get hashCode =>
      Object.hash(fieldKey, value, source, verified, Object.hashAll(audit));

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FieldValue &&
            other.fieldKey == fieldKey &&
            other.value == value &&
            other.source == source &&
            other.verified == verified &&
            _auditEquals(other.audit, audit));
  }
}

/// Where a [FieldValue] came from (§9 RecordField.source).
enum ValueSource {
  /// Typed or corrected by a person.
  manual,

  /// Read from a photo by OCR.
  ocr,

  /// Proposed from an image model.
  aiVision,

  /// Proposed from a text model.
  aiText,

  /// Heard and transcribed.
  stt,

  /// Read from a barcode or QR code.
  barcode,

  /// Filled from a reference dataset.
  lookup,

  /// Copied from pinned context.
  context,

  /// Written by the system (clock, GPS, sequence).
  auto,

  /// Brought in with an imported table or bundle.
  import,
}

/// One correction: what the value was, and what it became.
typedef FieldAudit = ({Object? previousValue, Object? newValue});

bool _auditEquals(List<FieldAudit> left, List<FieldAudit> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index++) {
    if (left[index].previousValue != right[index].previousValue ||
        left[index].newValue != right[index].newValue) {
      return false;
    }
  }
  return true;
}
