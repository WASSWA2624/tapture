import 'package:tapture/features/reference/domain/reference_dataset.dart';
import 'package:test/test.dart';

import '../reference_fixtures.dart';

void main() {
  test('datasets with the same columns in the same order are equal and hash '
      'alike', () {
    final ReferenceDataset a = aDataset(columns: <String>['code', 'name']);
    final ReferenceDataset b = aDataset(
      columns: List<String>.of(<String>['code', 'name']),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(<ReferenceDataset>{a, b}, hasLength(1));
  });

  test('the same columns in another order are a different dataset', () {
    expect(
      aDataset(columns: <String>['code', 'name']),
      isNot(aDataset(columns: <String>['name', 'code'])),
    );
  });

  test('every header field takes part in equality', () {
    final ReferenceDataset base = aDataset();
    final List<ReferenceDataset> variants = <ReferenceDataset>[
      base.copyWith(id: 'other'),
      base.copyWith(name: 'Other'),
      base.copyWith(keyColumn: 'name'),
      base.copyWith(source: DatasetSource.json),
      base.copyWith(importedAt: fixtureImportedAt.add(const Duration(days: 1))),
      base.copyWith(rowCount: 9),
      base.copyWith(duplicatesAllowed: true),
      base.copyWith(projectId: 'p1'),
      base.copyWith(sourceFile: 'other.csv'),
    ];
    for (final ReferenceDataset variant in variants) {
      expect(variant, isNot(base));
    }
  });

  test('copyWith replaces only the named fields', () {
    final ReferenceDataset base = aDataset(projectId: 'p1', rowCount: 3);
    final ReferenceDataset next = base.copyWith(
      rowCount: 4,
      duplicatesAllowed: true,
    );
    expect(next.rowCount, 4);
    expect(next.duplicatesAllowed, isTrue);
    expect(next.copyWith(rowCount: 3, duplicatesAllowed: false), base);
  });

  test('copyWith can clear the project id, which a null argument alone '
      'cannot', () {
    final ReferenceDataset scoped = aDataset(projectId: 'p1');
    expect(scoped.copyWith().projectId, 'p1');
    expect(scoped.copyWith(clearProjectId: true).projectId, isNull);
    expect(scoped.copyWith(projectId: 'p2').projectId, 'p2');
  });
}
