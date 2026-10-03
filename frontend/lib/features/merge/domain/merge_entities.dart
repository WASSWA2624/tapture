import 'package:tapture/core/db/vector_relation.dart';

import 'version_vector.dart';

/// Classifies each entity from its version vectors (task 019).
///
/// Order is project, templates, reference data, records, record fields,
/// then files.
final class MergeEntities {
  /// One decision per entity, in dependency order.
  static List<EntityDecision> classify(List<MergeEntity> entities) {
    final List<MergeEntity> ordered = List<MergeEntity>.of(entities)
      ..sort(
        (MergeEntity a, MergeEntity b) =>
            _order(a.kind).compareTo(_order(b.kind)),
      );
    return <EntityDecision>[
      for (final MergeEntity entity in ordered) _one(entity),
    ];
  }

  static EntityDecision _one(MergeEntity entity) {
    if (!entity.localExists) {
      return EntityDecision.insert;
    }
    final VectorRelation relation =
        (entity.local ?? const VersionVector(<String, int>{})).compareTo(
          entity.incoming,
        );
    return switch (relation) {
      VectorRelation.dominated => EntityDecision.fastForward,
      VectorRelation.dominates || VectorRelation.equal => EntityDecision.ignore,
      VectorRelation.concurrent => EntityDecision.concurrent,
    };
  }

  static int _order(String kind) {
    return switch (kind) {
      'project' => 0,
      'templates' => 1,
      'reference' => 2,
      'records' => 3,
      'fields' => 4,
      _ => 5,
    };
  }
}

/// One entity and the vectors on each side.
typedef MergeEntity = ({
  String kind,
  bool localExists,
  VersionVector? local,
  VersionVector incoming,
});

/// What the plan does with one entity.
enum EntityDecision { insert, fastForward, ignore, concurrent }
