part of 'context_state.dart';

/// A named snapshot of level values and pins.
final class ContextPreset {
  /// Creates a preset.
  const ContextPreset({
    required this.id,
    required this.name,
    required this.values,
    required this.pinned,
    this.lastUsedAt,
  });

  /// Stable id.
  final String id;

  /// Operator-facing name, unique within the project.
  final String name;

  /// Level fieldKey → value.
  final Map<String, String> values;

  /// Pin fieldKey → value.
  final Map<String, String> pinned;

  /// When this preset was last applied, for list ordering.
  final DateTime? lastUsedAt;

  /// Returns a copy with the provided fields replaced.
  ContextPreset copyWith({
    String? id,
    String? name,
    Map<String, String>? values,
    Map<String, String>? pinned,
    DateTime? lastUsedAt,
  }) {
    return ContextPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      values: values ?? this.values,
      pinned: pinned ?? this.pinned,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    Object.hashAll(
      values.entries.map(
        (MapEntry<String, String> e) => Object.hash(e.key, e.value),
      ),
    ),
    Object.hashAll(
      pinned.entries.map(
        (MapEntry<String, String> e) => Object.hash(e.key, e.value),
      ),
    ),
    lastUsedAt,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ContextPreset &&
            other.id == id &&
            other.name == name &&
            _mapEquals(other.values, values) &&
            _mapEquals(other.pinned, pinned));
  }
}
