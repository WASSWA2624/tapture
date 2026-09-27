import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/vector_relation.dart';
import 'package:tapture/features/merge/domain/version_vectors.dart';

void main() {
  test('every pair of vectors is one relation, including empty ones', () {
    const VersionVector empty = VersionVector(<String, int>{});
    final VersionVector local = empty.increment('a');
    final VersionVector ahead = local.increment('a');
    expect(empty.compareTo(empty), VectorRelation.equal);
    expect(empty.compareTo(local), VectorRelation.dominated);
    expect(ahead.compareTo(local), VectorRelation.dominates);
    expect(
      const VersionVector(<String, int>{
        'a': 2,
      }).compareTo(const VersionVector(<String, int>{'b': 1})),
      VectorRelation.concurrent,
    );
    expect(local.merge(ahead).counters['a'], 2);
  });
}
