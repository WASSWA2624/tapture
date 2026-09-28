import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  test('a variance keeps the raw values beside the normalised verdict', () {
    final FieldVariance row = VarianceComputation.compare(
      recorded: const <String, Object?>{'serial': 'ABB-1234'},
      found: const <String, Object?>{'serial': 'abb 1234'},
      fieldKeys: const <String>['serial'],
    ).single;
    expect(row.status, VarianceStatus.match);
    expect(row.recorded, 'ABB-1234');
    expect(row.found, 'abb 1234');
    expect(row.fieldKey, 'serial');
  });

  test('every variance status is one a comparison can produce', () {
    final List<FieldVariance> rows = VarianceComputation.compare(
      recorded: const <String, Object?>{
        'same': 'Good',
        'other': 'Good',
        'gone': 'Good',
      },
      found: const <String, Object?>{'same': 'good', 'other': 'Faulty'},
      fieldKeys: const <String>['same', 'other', 'gone'],
    );
    expect(
      rows.map((FieldVariance row) => row.status).toSet(),
      VarianceStatus.values.toSet(),
    );
  });

  test('a variance of two absent values is a match that keeps both nulls', () {
    final FieldVariance row = VarianceComputation.compare(
      recorded: const <String, Object?>{},
      found: const <String, Object?>{},
      fieldKeys: const <String>['note'],
    ).single;
    expect(row.status, VarianceStatus.match);
    expect(row.recorded, isNull);
    expect(row.found, isNull);
  });

  test('a non-text value is compared by its text form', () {
    final FieldVariance row = VarianceComputation.compare(
      recorded: const <String, Object?>{'qty': 12},
      found: const <String, Object?>{'qty': '12'},
      fieldKeys: const <String>['qty'],
    ).single;
    expect(row.status, VarianceStatus.match);
    expect(row.recorded, 12);
    expect(row.found, '12');
  });
}
