import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/record_flag.dart';

void main() {
  test('the six flags of spec §42 and §55.2 are the whole set', () {
    expect(RecordFlag.values.map((RecordFlag flag) => flag.name), <String>[
      'hasPhotos',
      'hasDuplicate',
      'hasConflict',
      'hasVariance',
      'evidenceRemoved',
      'mergedFromBundle',
    ]);
  });

  test('every flag reads back from its stored spelling', () {
    for (final RecordFlag flag in RecordFlag.values) {
      expect(RecordFlag.fromStored(flag.stored), flag);
    }
  });

  test('fromStored folds case and underscores', () {
    expect(RecordFlag.fromStored('HAS_PHOTOS'), RecordFlag.hasPhotos);
    expect(
      RecordFlag.fromStored('evidence_removed'),
      RecordFlag.evidenceRemoved,
    );
    expect(RecordFlag.fromStored(' hasconflict '), RecordFlag.hasConflict);
  });

  test('an unknown spelling reads as null, not a throw', () {
    expect(RecordFlag.fromStored('notInRegister'), isNull);
    expect(RecordFlag.fromStored(''), isNull);
  });
}
