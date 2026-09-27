import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/record_sort_key.dart';

void main() {
  test('a list sorts by number, capture date or name', () {
    expect(RecordSortKey.values, <RecordSortKey>[
      RecordSortKey.number,
      RecordSortKey.capturedAt,
      RecordSortKey.name,
    ]);
  });

  test('each key is stored as its own name, name included', () {
    expect(RecordSortKey.number.stored, 'number');
    expect(RecordSortKey.capturedAt.stored, 'capturedAt');
    expect(RecordSortKey.name.stored, 'name');
  });

  test('every key reads back from its stored spelling', () {
    for (final RecordSortKey key in RecordSortKey.values) {
      expect(RecordSortKey.fromStored(key.stored), key);
    }
    expect(RecordSortKey.fromStored('CAPTURED_AT'), RecordSortKey.capturedAt);
  });

  test('an unknown key reads as null', () {
    expect(RecordSortKey.fromStored('identifier'), isNull);
  });
}
