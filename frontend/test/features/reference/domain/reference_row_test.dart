import 'package:tapture/features/reference/domain/reference_row.dart';
import 'package:test/test.dart';

import '../reference_fixtures.dart';

void main() {
  test('rows with the same cells are equal whatever the cell order', () {
    final ReferenceRow a = aReferenceRow(
      id: 'r1',
      values: <String, String>{'code': 'ACME', 'name': 'Acme'},
    );
    final ReferenceRow b = aReferenceRow(
      id: 'r1',
      values: <String, String>{'name': 'Acme', 'code': 'ACME'},
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(<ReferenceRow>{a, b}, hasLength(1));
  });

  test('one differing cell, an extra cell or the device flag tells rows '
      'apart', () {
    final ReferenceRow base = aReferenceRow(
      id: 'r1',
      values: <String, String>{'code': 'ACME', 'name': 'Acme'},
    );
    expect(
      base,
      isNot(
        base.copyWith(values: <String, String>{'code': 'ACME', 'name': 'Acm'}),
      ),
    );
    expect(
      base,
      isNot(
        base.copyWith(
          values: <String, String>{'code': 'ACME', 'name': 'Acme', 'x': ''},
        ),
      ),
    );
    expect(base, isNot(base.copyWith(addedOnDevice: true)));
    expect(base, isNot(base.copyWith(key: 'acme')));
    expect(base, isNot(base.copyWith(datasetId: 'other')));
  });

  test('copyWith replaces only the named fields', () {
    final ReferenceRow base = aReferenceRow(id: 'r1', addedOnDevice: true);
    final ReferenceRow next = base.copyWith(key: 'BETA');
    expect(next.key, 'BETA');
    expect(next.values, base.values);
    expect(next.addedOnDevice, isTrue);
    expect(next.copyWith(key: 'ACME'), base);
  });
}
