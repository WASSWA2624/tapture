/// One line read from a signed attendance sheet, with a confidence per cell.
final class AttendanceReading {
  /// Creates a reading. Confidences are 0 to 1.
  const AttendanceReading({
    required this.name,
    this.title = '',
    this.organisation = '',
    this.signaturePresent = false,
    this.nameConfidence = 0,
    this.titleConfidence = 0,
    this.organisationConfidence = 0,
    this.signatureConfidence = 0,
  });

  /// Name cell.
  final String name;

  /// Title cell.
  final String title;

  /// Organisation cell.
  final String organisation;

  /// Whether the signature cell had a mark.
  final bool signaturePresent;

  /// Confidence of [name].
  final double nameConfidence;

  /// Confidence of [title].
  final double titleConfidence;

  /// Confidence of [organisation].
  final double organisationConfidence;

  /// Confidence of the signature cell.
  final double signatureConfidence;

  /// Returns a copy with the provided fields replaced.
  AttendanceReading copyWith({
    String? name,
    String? title,
    String? organisation,
    bool? signaturePresent,
  }) {
    return AttendanceReading(
      name: name ?? this.name,
      title: title ?? this.title,
      organisation: organisation ?? this.organisation,
      signaturePresent: signaturePresent ?? this.signaturePresent,
      nameConfidence: nameConfidence,
      titleConfidence: titleConfidence,
      organisationConfidence: organisationConfidence,
      signatureConfidence: signatureConfidence,
    );
  }
}
