import 'package:tapture/core/errors/result.dart';

/// What review reads beside a record's values, and the two writes it makes
/// that are not value edits (task 016). Edits go through the records
/// feature's inline field editor; approval through `approveAndNext`.
abstract interface class ReviewRepository {
  /// What review shows beside [recordId]'s values: the fields still in an
  /// unresolved conflict, who verified each verified value, and the
  /// evidence each value was read from.
  Future<Result<ReviewFacts>> facts(String recordId);

  /// Marks every field in [fieldKeys] of [recordId] verified by this
  /// device's operator, now, leaving each value exactly as it was. A key
  /// with no stored value, or one already verified, is left alone.
  Future<Result<void>> verify(String recordId, List<String> fieldKeys);

  /// Makes [value] the final value of [fieldKey] on [recordId]. The raw and
  /// refined sides stay stored, so choosing again reverses it.
  Future<Result<void>> chooseFinal(
    String recordId,
    String fieldKey,
    String value,
  );
}

/// Where one piece of evidence came from.
enum EvidenceKind {
  /// A region of a photo, or the whole photo.
  photo,

  /// A page of a document.
  document,

  /// A passage of a transcript.
  transcript,
}

/// One evidence link of a value: its kind, the photo or document page, the
/// bounding region as stored JSON, the OCR snippet or transcript passage it
/// rests on, and the photo's stored pixel size, which places a pixel
/// region on it.
typedef ValueEvidence = ({
  EvidenceKind kind,
  String? photoId,
  int? page,
  String? regionJson,
  String? snippet,
  int? photoWidth,
  int? photoHeight,
});

/// What review reads beside a record: [conflicts] are field keys in an
/// unresolved conflict, [verifiedBy] names who verified each verified value
/// (blank when no operator was known), and [evidence] lists each value's
/// evidence by field key.
typedef ReviewFacts = ({
  Set<String> conflicts,
  Map<String, String> verifiedBy,
  Map<String, List<ValueEvidence>> evidence,
});

/// Facts with nothing in them.
const ReviewFacts noReviewFacts = (
  conflicts: <String>{},
  verifiedBy: <String, String>{},
  evidence: <String, List<ValueEvidence>>{},
);
