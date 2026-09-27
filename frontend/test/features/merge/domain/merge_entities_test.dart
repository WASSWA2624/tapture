import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_entities.dart';
import 'package:tapture/features/merge/domain/version_vectors.dart';

void main() {
  test('entities classify and stay in dependency order', () {
    const VersionVector local = VersionVector(<String, int>{'a': 1});
    final List<EntityDecision> decisions = MergeEntities.classify(<MergeEntity>[
      (kind: 'files', localExists: false, local: null, incoming: local),
      (
        kind: 'project',
        localExists: true,
        local: local,
        incoming: const VersionVector(<String, int>{'a': 2}),
      ),
    ]);
    expect(decisions, <EntityDecision>[
      EntityDecision.fastForward,
      EntityDecision.insert,
    ]);
  });
}
