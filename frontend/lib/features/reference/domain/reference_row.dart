/// One row in a [ReferenceDataset].
final class ReferenceRow {
  /// Creates a row. [values] are keyed by column name.
  const ReferenceRow({
    required this.id,
    required this.datasetId,
    required this.key,
    required this.values,
    this.addedOnDevice = false,
  });

  /// Stable merge id.
  final String id;

  /// Dataset this row belongs to.
  final String datasetId;

  /// Key as imported or typed.
  final String key;

  /// Cell values keyed by column name.
  final Map<String, String> values;

  /// Whether the operator added this row on the device.
  final bool addedOnDevice;

  /// Returns a copy with the provided fields replaced.
  ReferenceRow copyWith({
    String? id,
    String? datasetId,
    String? key,
    Map<String, String>? values,
    bool? addedOnDevice,
  }) {
    return ReferenceRow(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      key: key ?? this.key,
      values: values ?? this.values,
      addedOnDevice: addedOnDevice ?? this.addedOnDevice,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    datasetId,
    key,
    Object.hashAll(
      values.entries.map(
        (MapEntry<String, String> e) => Object.hash(e.key, e.value),
      ),
    ),
    addedOnDevice,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReferenceRow &&
            other.id == id &&
            other.datasetId == datasetId &&
            other.key == key &&
            _mapEquals(other.values, values) &&
            other.addedOnDevice == addedOnDevice);
  }
}

bool _mapEquals(Map<String, String> left, Map<String, String> right) {
  if (identical(left, right)) {
    return true;
  }
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
