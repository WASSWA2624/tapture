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

  /// Returns a copy with the provided fields replaced. Replacement maps are
  /// copied unmodifiable (FE-CODE-04).
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
      values: values == null
          ? this.values
          : Map<String, String>.unmodifiable(values),
      pinned: pinned == null
          ? this.pinned
          : Map<String, String>.unmodifiable(pinned),
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// Whether [state] holds exactly what applying this preset writes: its
  /// value on every level it names, nothing on the levels it omits, and its
  /// pins.
  bool isAppliedTo(ContextState state) {
    for (final ContextLevel level in state.levels) {
      final String want = values[level.fieldKey] ?? '';
      if ((state.values[level.fieldKey] ?? '') != want) {
        return false;
      }
    }
    return _mapEquals(pinned, state.pinned);
  }

  /// [lastUsedAt] is ordering metadata, not identity, so it is in neither
  /// [==] nor [hashCode].
  @override
  int get hashCode => Object.hash(
    id,
    name,
    Object.hashAllUnordered(
      values.entries.map(
        (MapEntry<String, String> e) => Object.hash(e.key, e.value),
      ),
    ),
    Object.hashAllUnordered(
      pinned.entries.map(
        (MapEntry<String, String> e) => Object.hash(e.key, e.value),
      ),
    ),
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
