import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/normalise/fuzzy_matcher.dart';
import 'package:tapture/features/reference/domain/lookup_matcher.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';

import '../reference_fixtures.dart';

void main() {
  final List<ReferenceRow> rows = <ReferenceRow>[
    aReferenceRow(
      id: '1',
      key: 'ACME',
      values: <String, String>{'code': 'ACME', 'name': 'Acme Supplies'},
    ),
    aReferenceRow(
      id: '2',
      key: 'BETA',
      values: <String, String>{'code': 'BETA', 'name': 'Beta Trading'},
    ),
    aReferenceRow(
      id: '3',
      key: 'GAMMA',
      values: <String, String>{'code': 'GAMMA', 'name': 'Gamma & Sons, Ltd.'},
    ),
    aReferenceRow(
      id: '4',
      key: 'acme',
      values: <String, String>{'code': 'acme', 'name': 'Acme Supplies (old)'},
    ),
  ];

  List<String> ids(List<ReferenceRow> found) {
    return <String>[for (final ReferenceRow row in found) row.id];
  }

  group('key variants', () {
    test('an exact key wins over a key that only matches once folded', () {
      expect(
        ids(
          LookupMatcher.match(
            rows: rows,
            query: 'acme',
            matchColumns: const <String>['code'],
          ),
        ),
        <String>['4'],
      );
    });

    test('a key typed in another case still finds its row', () {
      expect(
        ids(
          LookupMatcher.match(
            rows: rows,
            query: 'beta',
            matchColumns: const <String>['code'],
          ),
        ),
        <String>['2'],
      );
    });

    test('whitespace around the key is ignored', () {
      expect(
        ids(
          LookupMatcher.match(
            rows: rows,
            query: '  BETA\t',
            matchColumns: const <String>['code'],
          ),
        ),
        <String>['2'],
      );
    });

    test('every row sharing a key is returned so a picker can ask', () {
      final List<ReferenceRow> twins = <ReferenceRow>[
        aReferenceRow(id: 'a', key: 'X1'),
        aReferenceRow(id: 'b', key: 'X1'),
        aReferenceRow(id: 'c', key: 'X2'),
      ];
      expect(
        ids(
          LookupMatcher.match(
            rows: twins,
            query: 'X1',
            matchColumns: const <String>['code'],
          ),
        ),
        <String>['a', 'b'],
      );
    });
  });

  group('name variants', () {
    test('case, repeated whitespace and punctuation do not stop a match', () {
      for (final String query in <String>[
        'beta trading',
        'BETA   TRADING',
        ' Beta\nTrading ',
        'Beta Trading!',
      ]) {
        expect(
          ids(
            LookupMatcher.match(
              rows: rows,
              query: query,
              matchColumns: const <String>['name'],
            ),
          ),
          <String>['2'],
          reason: query,
        );
      }
    });

    test('punctuation inside a name is dropped rather than split on', () {
      expect(
        ids(
          LookupMatcher.match(
            rows: rows,
            query: 'gamma sons ltd',
            matchColumns: const <String>['name'],
          ),
        ),
        <String>['3'],
      );
      expect(
        LookupMatcher.match(
          rows: rows,
          query: 'gamma-sons ltd',
          matchColumns: const <String>['name'],
        ),
        isEmpty,
      );
    });

    test('normalise folds case, whitespace and punctuation as a table', () {
      const Map<String, String> table = <String, String>{
        'Acme Supplies': 'acme supplies',
        '  Acme   Supplies ': 'acme supplies',
        'ACME-SUPPLIES': 'acmesupplies',
        'Acme, Inc.': 'acme inc',
        'tab\tsplit\r\nline': 'tab split line',
        'Café Ölç': 'café ölç',
        '': '',
        '!!!': '',
      };
      for (final MapEntry<String, String> entry in table.entries) {
        expect(
          LookupMatcher.normalise(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });
  });

  group('match column order', () {
    final List<ReferenceRow> crossed = <ReferenceRow>[
      aReferenceRow(
        id: 'by-name',
        key: 'B1',
        values: <String, String>{'code': 'B1', 'name': 'BETA'},
      ),
      aReferenceRow(
        id: 'by-code',
        key: 'BETA',
        values: <String, String>{'code': 'BETA', 'name': 'Other'},
      ),
    ];

    test('the first column with a hit answers before later ones are tried', () {
      expect(
        ids(
          LookupMatcher.match(
            rows: crossed,
            query: 'BETA',
            matchColumns: const <String>['name', 'code'],
          ),
        ),
        <String>['by-name'],
      );
      expect(
        ids(
          LookupMatcher.match(
            rows: crossed,
            query: 'BETA',
            matchColumns: const <String>['code', 'name'],
          ),
        ),
        <String>['by-code'],
      );
    });

    test('without match columns the key column is the only one tried', () {
      expect(
        ids(
          LookupMatcher.match(
            rows: crossed,
            query: 'beta',
            matchColumns: const <String>[],
            keyColumn: 'code',
          ),
        ),
        <String>['by-code'],
      );
      expect(
        LookupMatcher.match(
          rows: crossed,
          query: 'beta',
          matchColumns: const <String>[],
        ),
        isEmpty,
      );
    });

    test('the pseudo column key and an empty column name read the row key', () {
      final List<ReferenceRow> keyed = <ReferenceRow>[
        aReferenceRow(
          id: 'k',
          key: 'ROW-KEY',
          values: <String, String>{'name': 'Anything'},
        ),
      ];
      for (final String column in <String>['key', '']) {
        expect(
          ids(
            LookupMatcher.match(
              rows: keyed,
              query: 'row-key',
              matchColumns: <String>[column],
            ),
          ),
          <String>['k'],
          reason: 'column "$column"',
        );
      }
    });

    test('an empty or blank query matches nothing', () {
      for (final String query in <String>['', '   ', '\n']) {
        expect(
          LookupMatcher.match(
            rows: rows,
            query: query,
            matchColumns: const <String>['code', 'name'],
          ),
          isEmpty,
          reason: '"$query"',
        );
      }
    });
  });

  group('fuzzy fallback', () {
    double score(String query, String candidate) {
      return FuzzyMatcher.scorePair(
        LookupMatcher.normalise(query),
        LookupMatcher.normalise(candidate),
      );
    }

    test('real-world name variants score as the table expects', () {
      const List<(String, String, double)> table = <(String, String, double)>[
        ('ACME Supplies Ltd', 'Acme Supplies Ltd.', 1.0),
        ('Acme Suplies', 'Acme Supplies', 0.6872),
        ('Acme Supply', 'Acme Supplies', 0.5949),
        ('Beta Trading Co', 'Beta Trading Company', 0.65),
        ('Gamma & Sons', 'Gamma and Sons', 0.6952),
        ('Delta Freight Uganda', 'Delta Freight (U) Ltd', 0.64),
        ('Kampala Pharmacy', 'Kampla Pharmacy', 0.6958),
        ('St. Mary Hospital', 'Saint Mary Hospital', 0.7053),
        ('Acme Supplies', 'Beta Trading', 0.0923),
        ('Acme Supplies', 'Completely Different', 0.12),
      ];
      for (final (String query, String candidate, double expected) in table) {
        expect(
          score(query, candidate),
          closeTo(expected, 0.0005),
          reason: '$query vs $candidate',
        );
      }
    });

    test('a near miss ranks first at a permissive threshold and is withheld '
        'at a strict one, so the caller offers rather than fills', () {
      List<String> ranked(double threshold) {
        return <String>[
          for (final ({ReferenceRow item, double score}) hit
              in FuzzyMatcher.rank(
                items: rows,
                query: 'Acme Suplies',
                textOf: (ReferenceRow row) => row.values['name'] ?? '',
                threshold: threshold,
                normalise: LookupMatcher.normalise,
              ))
            hit.item.id,
        ];
      }

      expect(ranked(0.5), <String>['1', '4']);
      expect(ranked(0.8), isEmpty);
    });

    test('a stranger never clears the threshold', () {
      expect(
        FuzzyMatcher.rank(
          items: rows,
          query: 'Zulu Logistics',
          textOf: (ReferenceRow row) => row.values['name'] ?? '',
          threshold: 0.5,
          normalise: LookupMatcher.normalise,
        ),
        isEmpty,
      );
    });
  });
}
