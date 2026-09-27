import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/domain.dart';

void main() {
  const MergeCounts none = (
    newRecords: 0,
    updatedRecords: 0,
    newPhotos: 0,
    photosHere: 3,
    deletions: 0,
    kept: 2,
    elsewhere: 1,
  );

  MergePlan plan({
    Map<String, List<Map<String, Object?>>> inserts =
        const <String, List<Map<String, Object?>>>{},
    List<FieldConflict> conflicts = const <FieldConflict>[],
  }) {
    return MergePlan(
      inserts: inserts,
      files: const <({String entry, String target})>[],
      settled:
          const <
            ({
              String rowId,
              String fieldKey,
              String previous,
              String value,
              bool verified,
              SettlementRule rule,
            })
          >[],
      conflicts: conflicts,
      counts: none,
      insertedRecords: const <String>[],
    );
  }

  test('a plan that only counts what is already here is empty', () {
    expect(plan().isEmpty, isTrue);
    expect(
      plan(
        inserts: const <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[],
        },
      ).isEmpty,
      isTrue,
    );
  });

  test('a row to insert or a conflict to settle is not empty', () {
    expect(
      plan(
        inserts: const <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[
            <String, Object?>{'id': 'r1'},
          ],
        },
      ).isEmpty,
      isFalse,
    );
    expect(
      plan(
        conflicts: const <FieldConflict>[
          FieldConflict(
            kind: ConflictKind.status,
            table: 'records',
            rowId: 'r1',
            recordId: 'r1',
            fieldKey: '',
            fieldLabel: '',
            recordLabel: '',
            mine: 'captured',
            theirs: 'approved',
            mineDevice: '',
            theirsDevice: '',
            mineAt: null,
            theirsAt: null,
          ),
        ],
      ).isEmpty,
      isFalse,
    );
  });
}
