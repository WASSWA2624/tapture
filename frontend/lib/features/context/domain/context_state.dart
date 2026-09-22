part 'context_level.dart';
part 'context_preset.dart';

/// Current hierarchy definition, level values and pinned fields for a project.
final class ContextState {
  /// Creates a state. Empty levels and pins mean the feature is dormant.
  const ContextState({
    this.levels = const <ContextLevel>[],
    this.values = const <String, String>{},
    this.pinned = const <String, String>{},
  });

  /// Ordered hierarchy levels.
  final List<ContextLevel> levels;

  /// Level fieldKey → value.
  final Map<String, String> values;

  /// Stickable non-hierarchical fieldKey → value.
  final Map<String, String> pinned;

  /// Whether nothing is defined or pinned.
  bool get isEmpty => levels.isEmpty && pinned.isEmpty;

  /// Returns a copy with the provided fields replaced.
  ContextState copyWith({
    List<ContextLevel>? levels,
    Map<String, String>? values,
    Map<String, String>? pinned,
  }) {
    return ContextState(
      levels: levels ?? this.levels,
      values: values ?? this.values,
      pinned: pinned ?? this.pinned,
    );
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(levels),
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
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ContextState &&
            _listEquals(other.levels, levels) &&
            _mapEquals(other.values, values) &&
            _mapEquals(other.pinned, pinned));
  }
}

bool _listEquals(List<ContextLevel> left, List<ContextLevel> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final MapEntry<String, String> entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
