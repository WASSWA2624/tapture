/// One record type of the full catalogue: the pack of fields every template
/// of that type shares, and how such records are captured, assisted, output
/// and reviewed. The wording is catalogue data (FE-L10N-07).
final class ShippedRecordType {
  /// Creates a record type.
  const ShippedRecordType({
    required this.code,
    required this.title,
    required this.kind,
    this.capture = '',
    this.aiAssistance = '',
    this.outputs = '',
    this.review = '',
  });

  /// Pack code, for example `OBS`.
  final String code;

  /// Record type name, for example `Observation / evidence capture`.
  final String title;

  /// Template kind every template of this type carries.
  final String kind;

  /// How evidence for such a record is captured.
  final String capture;

  /// What an AI may do with it.
  final String aiAssistance;

  /// What the record produces.
  final String outputs;

  /// What a reviewer checks before approval.
  final String review;
}
