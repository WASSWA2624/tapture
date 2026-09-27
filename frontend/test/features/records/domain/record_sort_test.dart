import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/record_sort.dart';

void main() {
  test('the default sort is number, newest first', () {
    expect(const RecordSort(), RecordSort.newestFirst);
    expect(RecordSort.newestFirst.key, RecordSortKey.number);
    expect(RecordSort.newestFirst.ascending, isFalse);
  });

  test('every key and direction survives a JSON round-trip', () {
    for (final RecordSortKey key in RecordSortKey.values) {
      for (final bool ascending in <bool>[true, false]) {
        final RecordSort sort = RecordSort(key: key, ascending: ascending);
        expect(RecordSort.fromJson(sort.toJson()), sort);
      }
    }
  });

  test('toJson writes the stored key and the direction', () {
    expect(
      const RecordSort(key: RecordSortKey.name, ascending: true).toJson(),
      <String, Object?>{'key': 'name', 'ascending': true},
    );
  });

  test('fromJson falls back to the default for missing or unknown parts', () {
    expect(
      RecordSort.fromJson(const <String, Object?>{}),
      RecordSort.newestFirst,
    );
    expect(
      RecordSort.fromJson(const <String, Object?>{
        'key': 'colour',
        'ascending': 'yes',
        'extra': 1,
      }),
      RecordSort.newestFirst,
    );
    expect(
      RecordSort.fromJson(const <String, Object?>{'key': 'capturedAt'}),
      const RecordSort(key: RecordSortKey.capturedAt),
    );
  });

  test('reversed flips only the direction', () {
    const RecordSort byName = RecordSort(
      key: RecordSortKey.name,
      ascending: true,
    );
    expect(byName.reversed(), const RecordSort(key: RecordSortKey.name));
    expect(byName.reversed().reversed(), byName);
  });

  test('copyWith replaces only what it is given', () {
    const RecordSort sort = RecordSort();
    expect(
      sort.copyWith(key: RecordSortKey.capturedAt),
      const RecordSort(key: RecordSortKey.capturedAt),
    );
    expect(sort.copyWith(ascending: true).key, RecordSortKey.number);
    expect(sort.copyWith(), sort);
    expect(sort.copyWith().hashCode, sort.hashCode);
  });
}
