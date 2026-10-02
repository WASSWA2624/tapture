import 'bundle_format.dart';
import 'bundle_version_vectors.dart';

export 'bundle_version_vectors.dart';

/// Shared validation and row conversion for the package's causal metadata.
abstract final class BundleVectors {
  /// Reads strictly typed clocks. Older version-one packages may omit them.
  static BundleVersionVectors decode(Object? value) {
    if (value == null) return const <String, Map<String, Map<String, int>>>{};
    if (value is! Map<String, Object?>) {
      throw const FormatException('Invalid version vectors.');
    }
    final BundleVersionVectors result =
        <String, Map<String, Map<String, int>>>{};
    for (final MapEntry<String, Object?> table in value.entries) {
      if ((!BundleFormat.insertOrder.contains(table.key) &&
              !BundleFormat.referenceTables.contains(table.key)) ||
          table.value is! Map<String, Object?>) {
        throw const FormatException('Invalid vector entity table.');
      }
      final Map<String, Map<String, int>> entities =
          <String, Map<String, int>>{};
      for (final MapEntry<String, Object?> entity
          in (table.value! as Map<String, Object?>).entries) {
        if (entity.key.isEmpty || entity.value is! Map<String, Object?>) {
          throw const FormatException('Invalid vector entity.');
        }
        final Map<String, int> counters = <String, int>{};
        for (final MapEntry<String, Object?> counter
            in (entity.value! as Map<String, Object?>).entries) {
          if (counter.key.isEmpty ||
              counter.value is! int ||
              (counter.value! as int) < 0) {
            throw const FormatException('Invalid vector counter.');
          }
          counters[counter.key] = counter.value! as int;
        }
        entities[entity.key] = Map<String, int>.unmodifiable(counters);
      }
      result[table.key] = Map<String, Map<String, int>>.unmodifiable(entities);
    }
    return Map<String, Map<String, Map<String, int>>>.unmodifiable(result);
  }

  /// Converts clocks to planner rows; these rows are never table entries.
  static List<Map<String, Object?>> rows(BundleVersionVectors vectors) =>
      <Map<String, Object?>>[
        for (final table in vectors.entries)
          for (final entity in table.value.entries)
            for (final counter in entity.value.entries)
              <String, Object?>{
                'id': '${table.key}/${entity.key}/${counter.key}',
                'entity_type': table.key,
                'entity_id': entity.key,
                'device_id': counter.key,
                'seen_rev': counter.value,
              },
      ];
}
