/// One person at a meeting. A staff link is set only after it is accepted.
final class Attendee {
  /// Creates an attendee. [status] defaults to present.
  const Attendee({
    required this.id,
    required this.name,
    this.title = '',
    this.organisation = '',
    this.contact = '',
    this.status = AttendanceStatus.present,
    this.signaturePresent = false,
    this.staffId,
    this.suggestedStaffId,
    this.matchScore,
  });

  /// Rebuilds an attendee written by [toJson].
  factory Attendee.fromJson(Map<String, Object?> json) {
    final Object? score = json['matchScore'];
    return Attendee(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      organisation: json['organisation'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      status: json['status'] == AttendanceStatus.apology.name
          ? AttendanceStatus.apology
          : AttendanceStatus.present,
      signaturePresent: json['signaturePresent'] == true,
      staffId: json['staffId'] as String?,
      suggestedStaffId: json['suggestedStaffId'] as String?,
      matchScore: score is num ? score.toDouble() : null,
    );
  }

  /// Stable id.
  final String id;

  /// Name as captured.
  final String name;

  /// Role or job title as captured.
  final String title;

  /// Organisation as captured.
  final String organisation;

  /// Contact as captured.
  final String contact;

  /// Present or apology.
  final AttendanceStatus status;

  /// Whether a signature was on the sheet.
  final bool signaturePresent;

  /// Staff row the person accepted. Null until they do.
  final String? staffId;

  /// Staff row offered, not linked.
  final String? suggestedStaffId;

  /// Score of [suggestedStaffId], when one was offered.
  final double? matchScore;

  /// Apologies are recorded and are not attendance.
  bool get countsAsAttendance => status == AttendanceStatus.present;

  /// JSON for the meeting document.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'title': title,
      'organisation': organisation,
      'contact': contact,
      'status': status.name,
      'signaturePresent': signaturePresent,
      'staffId': staffId,
      'suggestedStaffId': suggestedStaffId,
      'matchScore': matchScore,
    };
  }

  /// Returns a copy with the provided fields replaced.
  Attendee copyWith({
    String? name,
    String? title,
    String? organisation,
    String? contact,
    AttendanceStatus? status,
    bool? signaturePresent,
    String? staffId,
    String? suggestedStaffId,
    double? matchScore,
    bool clearStaffId = false,
    bool clearSuggestion = false,
  }) {
    return Attendee(
      id: id,
      name: name ?? this.name,
      title: title ?? this.title,
      organisation: organisation ?? this.organisation,
      contact: contact ?? this.contact,
      status: status ?? this.status,
      signaturePresent: signaturePresent ?? this.signaturePresent,
      staffId: clearStaffId ? null : (staffId ?? this.staffId),
      suggestedStaffId: clearSuggestion
          ? null
          : (suggestedStaffId ?? this.suggestedStaffId),
      matchScore: clearSuggestion ? null : (matchScore ?? this.matchScore),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Attendee &&
        other.id == id &&
        other.name == name &&
        other.title == title &&
        other.organisation == organisation &&
        other.contact == contact &&
        other.status == status &&
        other.signaturePresent == signaturePresent &&
        other.staffId == staffId &&
        other.suggestedStaffId == suggestedStaffId &&
        other.matchScore == matchScore;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    title,
    organisation,
    contact,
    status,
    signaturePresent,
    staffId,
    suggestedStaffId,
    matchScore,
  );
}

/// Whether a person is in the room or sent apologies.
enum AttendanceStatus {
  /// Counted in attendance.
  present,

  /// Recorded, and never counted as attendance.
  apology,
}
