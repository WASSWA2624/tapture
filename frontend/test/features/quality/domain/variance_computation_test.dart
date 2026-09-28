import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  test('variance matches the normalised value and flags a real change', () {
    final List<FieldVariance> rows = VarianceComputation.compare(
      recorded: const <String, Object?>{
        'serial': 'ABB-1234',
        'note': 'Worn',
        'gone': 'Yes',
      },
      found: const <String, Object?>{
        'serial': 'abb 1234',
        'note': 'New',
        'gone': '',
      },
      fieldKeys: const <String>['serial', 'note', 'gone'],
    );
    expect(rows[0].status, VarianceStatus.match);
    expect(rows[1].status, VarianceStatus.changed);
    expect(rows[2].status, VarianceStatus.missing);
  });

  test('the specification example comes out field for field', () {
    final List<FieldVariance> rows = VarianceComputation.compare(
      recorded: const <String, Object?>{
        'location': 'Laboratory',
        'condition': 'Good',
        'serial': 'SN458923',
        'custodian': 'J. Okello',
      },
      found: const <String, Object?>{
        'location': 'Theatre',
        'condition': 'Faulty',
        'serial': 'SN458923',
        'custodian': 'M. Nabbosa',
      },
      fieldKeys: const <String>['location', 'condition', 'serial', 'custodian'],
    );
    expect(
      rows.map(
        (FieldVariance row) => (row.fieldKey, row.recorded, row.found, row.status),
      ),
      <(String, Object?, Object?, VarianceStatus)>[
        ('location', 'Laboratory', 'Theatre', VarianceStatus.changed),
        ('condition', 'Good', 'Faulty', VarianceStatus.changed),
        ('serial', 'SN458923', 'SN458923', VarianceStatus.match),
        ('custodian', 'J. Okello', 'M. Nabbosa', VarianceStatus.changed),
      ],
    );
  });

  test('nothing on either side is a match', () {
    final List<FieldVariance> rows = VarianceComputation.compare(
      recorded: const <String, Object?>{'note': ''},
      found: const <String, Object?>{'note': null},
      fieldKeys: const <String>['note'],
    );
    expect(rows.single.status, VarianceStatus.match);
  });

  test('a value found where the register had none is a change', () {
    final List<FieldVariance> rows = VarianceComputation.compare(
      recorded: const <String, Object?>{},
      found: const <String, Object?>{'note': 'Cracked'},
      fieldKeys: const <String>['note'],
    );
    expect(rows.single.status, VarianceStatus.changed);
  });

  test('a register value with nothing found is missing', () {
    for (final Object? blank in <Object?>[null, '', '   ']) {
      final List<FieldVariance> rows = VarianceComputation.compare(
        recorded: const <String, Object?>{'note': 'Worn'},
        found: <String, Object?>{'note': blank},
        fieldKeys: const <String>['note'],
      );
      expect(rows.single.status, VarianceStatus.missing, reason: '"$blank"');
    }
  });

  group('a formatting difference alone is a match', () {
    const Map<String, (String, String)> cases = <String, (String, String)>{
      'case': ('Good', 'GOOD'),
      'spacing': ('SN 458923', 'SN458923'),
      'punctuation': ('J. Okello', 'J Okello'),
      'diacritics': ('Café', 'cafe'),
      'surrounding whitespace': ('  Theatre ', 'Theatre'),
    };
    for (final MapEntry<String, (String, String)> entry in cases.entries) {
      test(entry.key, () {
        final List<FieldVariance> rows = VarianceComputation.compare(
          recorded: <String, Object?>{'f': entry.value.$1},
          found: <String, Object?>{'f': entry.value.$2},
          fieldKeys: const <String>['f'],
        );
        expect(rows.single.status, VarianceStatus.match);
      });
    }
  });

  test('one row per field key, in that order, even when neither side has it', () {
    final List<FieldVariance> rows = VarianceComputation.compare(
      recorded: const <String, Object?>{'b': 'x'},
      found: const <String, Object?>{'a': 'y'},
      fieldKeys: const <String>['c', 'b', 'a'],
    );
    expect(rows.map((FieldVariance row) => row.fieldKey), <String>[
      'c',
      'b',
      'a',
    ]);
    expect(rows.map((FieldVariance row) => row.status), <VarianceStatus>[
      VarianceStatus.match,
      VarianceStatus.missing,
      VarianceStatus.changed,
    ]);
  });

  test('a field not in the key list produces no row', () {
    final List<FieldVariance> rows = VarianceComputation.compare(
      recorded: const <String, Object?>{'serial': 'A', 'extra': 'B'},
      found: const <String, Object?>{'serial': 'Z', 'extra': 'Q'},
      fieldKeys: const <String>['serial'],
    );
    expect(rows.map((FieldVariance row) => row.fieldKey), <String>['serial']);
  });
}
