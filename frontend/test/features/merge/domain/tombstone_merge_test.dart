import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/tombstone_merge.dart';
import 'package:tapture/features/merge/domain/version_vectors.dart';

void main() {
  const VersionVector deleted = VersionVector(<String, int>{'a': 2});
  const VersionVector older = VersionVector(<String, int>{'a': 1});
  const VersionVector newer = VersionVector(<String, int>{'a': 3});

  test(
    'a later delete applies, a later edit conflicts, a repeat stays deleted',
    () {
      expect(
        TombstoneMerge.resolve(
          deleteVector: deleted,
          editVector: older,
          alreadyApplied: false,
        ),
        TombstoneOutcome.applyDelete,
      );
      expect(
        TombstoneMerge.resolve(
          deleteVector: deleted,
          editVector: newer,
          alreadyApplied: false,
        ),
        TombstoneOutcome.conflictEditAfterDelete,
      );
      expect(
        TombstoneMerge.resolve(
          deleteVector: deleted,
          editVector: older,
          alreadyApplied: true,
        ),
        TombstoneOutcome.ignoreDelete,
      );
      expect(
        TombstoneMerge.resolve(
          deleteVector: deleted,
          editVector: null,
          alreadyApplied: true,
        ),
        TombstoneOutcome.ignoreDelete,
      );
    },
  );
}
