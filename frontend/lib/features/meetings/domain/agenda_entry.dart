/// One discussion section on a meeting, in the order the person set.
final class AgendaEntry {
  /// Creates an agenda entry. [notes] are the discussion under it.
  const AgendaEntry({required this.id, required this.title, this.notes = ''});

  /// Rebuilds an entry written by [toJson].
  factory AgendaEntry.fromJson(Map<String, Object?> json) {
    return AgendaEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Stable id.
  final String id;

  /// Heading, stored as meeting content.
  final String title;

  /// Discussion written under this heading.
  final String notes;

  /// JSON for the meeting document.
  Map<String, Object?> toJson() {
    return <String, Object?>{'id': id, 'title': title, 'notes': notes};
  }

  /// Returns a copy with the provided fields replaced.
  AgendaEntry copyWith({String? title, String? notes}) {
    return AgendaEntry(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AgendaEntry &&
        other.id == id &&
        other.title == title &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(id, title, notes);
}
