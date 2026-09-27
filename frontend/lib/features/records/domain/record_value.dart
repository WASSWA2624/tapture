import 'package:tapture/core/widgets/fields/field_value.dart';

/// One value on a record, with where it came from and what happened to it.
///
/// The three stages stay side by side: [raw] is what was captured and is
/// never overwritten, [refined] is a correction or refinement written beside
/// it, and [approved] is the value an approval fixed (spec §9, FE-SEC-08).
final class RecordValue {
  /// Creates a value.
  const RecordValue({
    required this.fieldKey,
    this.raw = '',
    this.refined,
    this.approved,
    this.source = manualSource,
    this.confidence,
    this.band,
    this.verified = false,
    this.evidenceRemoved = false,
    this.retired = false,
    this.provider,
    this.model,
    this.method,
  });

  /// The stored source an operator's edit writes.
  static const String manualSource = 'manual';

  /// Template field key this value fills.
  final String fieldKey;

  /// What was captured, or empty when nothing was.
  final String raw;

  /// The refined or corrected value, when one was written.
  final String? refined;

  /// The approved (final) value, when an approval fixed one.
  final String? approved;

  /// The stored source string, as written (`TYPED`, `ocr`, `extraction`…).
  final String source;

  /// Confidence of the proposal that produced the value, 0 to 1.
  final double? confidence;

  /// The stored confidence band (`high`, `medium`, `reviewRequired`).
  final String? band;

  /// Whether an operator has confirmed the value.
  final bool verified;

  /// Whether every photo this value was read from has been removed.
  final bool evidenceRemoved;

  /// Whether the record's template no longer declares [fieldKey]. A retired
  /// value is kept and shown, never deleted.
  final bool retired;

  /// Online provider that proposed the value, when one did.
  final String? provider;

  /// Model that proposed the value, when one did.
  final String? model;

  /// Extraction method, such as local OCR, when one was used.
  final String? method;

  /// What the value reads as: [approved], else [refined], else [raw], taking
  /// the first that is not empty.
  String get display {
    final String? approved = this.approved;
    if (approved != null && approved.isNotEmpty) {
      return approved;
    }
    final String? refined = this.refined;
    if (refined != null && refined.isNotEmpty) {
      return refined;
    }
    return raw;
  }

  /// Whether the value reads as anything at all.
  bool get hasValue => display.isNotEmpty;

  /// [source] as the editor's [ValueSource].
  ValueSource get valueSource => sourceOf(source);

  /// The [ValueSource] a stored source string means, folding case and
  /// punctuation. An unknown source reads as [ValueSource.manual].
  static ValueSource sourceOf(String stored) {
    final String folded = stored.toLowerCase().replaceAll(_nonLetter, '');
    return _sources[folded] ?? ValueSource.manual;
  }

  /// This value as the inline field editor takes it (task 097).
  ///
  /// [decode] turns the stored text into the editor's typed value (a date,
  /// a number, a list of choices); without it the text is passed through.
  FieldValue toFieldValue([Object? Function(String text)? decode]) {
    final String text = display;
    return FieldValue(
      fieldKey: fieldKey,
      value: decode == null ? text : decode(text),
      source: valueSource,
      verified: verified,
    );
  }

  /// Returns a copy with the provided fields replaced. The `clear…` flags
  /// set the matching nullable field back to null.
  RecordValue copyWith({
    String? fieldKey,
    String? raw,
    String? refined,
    String? approved,
    String? source,
    double? confidence,
    String? band,
    bool? verified,
    bool? evidenceRemoved,
    bool? retired,
    String? provider,
    String? model,
    String? method,
    bool clearRefined = false,
    bool clearApproved = false,
    bool clearConfidence = false,
  }) {
    return RecordValue(
      fieldKey: fieldKey ?? this.fieldKey,
      raw: raw ?? this.raw,
      refined: clearRefined ? null : (refined ?? this.refined),
      approved: clearApproved ? null : (approved ?? this.approved),
      source: source ?? this.source,
      confidence: clearConfidence ? null : (confidence ?? this.confidence),
      band: band ?? this.band,
      verified: verified ?? this.verified,
      evidenceRemoved: evidenceRemoved ?? this.evidenceRemoved,
      retired: retired ?? this.retired,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      method: method ?? this.method,
    );
  }

  @override
  int get hashCode => Object.hash(
    fieldKey,
    raw,
    refined,
    approved,
    source,
    confidence,
    band,
    verified,
    evidenceRemoved,
    retired,
    provider,
    model,
    method,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecordValue &&
            other.fieldKey == fieldKey &&
            other.raw == raw &&
            other.refined == refined &&
            other.approved == approved &&
            other.source == source &&
            other.confidence == confidence &&
            other.band == band &&
            other.verified == verified &&
            other.evidenceRemoved == evidenceRemoved &&
            other.retired == retired &&
            other.provider == provider &&
            other.model == model &&
            other.method == method);
  }

  /// Names the field only: a value never reaches a log (FE-CODE-08).
  @override
  String toString() => 'RecordValue($fieldKey)';
}

final RegExp _nonLetter = RegExp('[^a-z]');

/// Stored source spellings in use, folded, and what each one means.
const Map<String, ValueSource> _sources = <String, ValueSource>{
  'manual': ValueSource.manual,
  'typed': ValueSource.manual,
  'operator': ValueSource.manual,
  'ocr': ValueSource.ocr,
  'extraction': ValueSource.aiVision,
  'ai': ValueSource.aiVision,
  'aivision': ValueSource.aiVision,
  'vision': ValueSource.aiVision,
  'aitext': ValueSource.aiText,
  'caption': ValueSource.aiText,
  'stt': ValueSource.stt,
  'speech': ValueSource.stt,
  'transcript': ValueSource.stt,
  'barcode': ValueSource.barcode,
  'qr': ValueSource.barcode,
  'lookup': ValueSource.lookup,
  'reference': ValueSource.lookup,
  'context': ValueSource.context,
  'default': ValueSource.auto,
  'auto': ValueSource.auto,
  'import': ValueSource.import,
  'imported': ValueSource.import,
  'importedtable': ValueSource.import,
  'bundle': ValueSource.import,
};
