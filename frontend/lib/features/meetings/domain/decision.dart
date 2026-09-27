/// One decision. [source] is the raw sentence it was taken from, if any.
final class Decision {
  /// Creates a decision. [source] is empty when somebody typed it.
  const Decision({required this.id, required this.text, this.source = ''});

  /// Rebuilds a decision written by [toJson].
  factory Decision.fromJson(Map<String, Object?> json) {
    return Decision(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  /// Stable id.
  final String id;

  /// What was decided, stored as meeting content.
  final String text;

  /// The raw notes or transcript passage this was read from.
  final String source;

  /// JSON for the meeting document.
  Map<String, Object?> toJson() {
    return <String, Object?>{'id': id, 'text': text, 'source': source};
  }

  /// Returns a copy with the provided fields replaced.
  Decision copyWith({String? text, String? source}) {
    return Decision(
      id: id,
      text: text ?? this.text,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Decision &&
        other.id == id &&
        other.text == text &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(id, text, source);
}
