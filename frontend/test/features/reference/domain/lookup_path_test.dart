import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/reference/domain/fuzzy_matcher.dart';
import 'package:tapture/features/reference/domain/lookup_binding.dart';
import 'package:tapture/features/reference/domain/lookup_matcher.dart';
import 'package:tapture/features/reference/domain/lookup_prefill.dart';
import 'package:tapture/features/reference/domain/lookup_unlink.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';

void main() {
  const List<ReferenceRow> rows = <ReferenceRow>[
    ReferenceRow(
      id: '1',
      datasetId: 'ds',
      key: 'ACME',
      values: <String, String>{'code': 'ACME', 'name': 'Acme Supplies'},
    ),
    ReferenceRow(
      id: '2',
      datasetId: 'ds',
      key: 'BETA',
      values: <String, String>{'code': 'BETA', 'name': 'Beta Trading'},
    ),
  ];

  test('lookup matcher hits key then normalised name', () {
    expect(
      LookupMatcher.match(
        rows: rows,
        query: 'ACME',
        matchColumns: const <String>['code', 'name'],
      ).single.id,
      '1',
    );
    expect(
      LookupMatcher.match(
        rows: rows,
        query: 'acme   supplies!',
        matchColumns: const <String>['name'],
      ).single.id,
      '1',
    );
  });

  test('fuzzy matcher scores real-world name variants', () {
    expect(
      FuzzyMatcher.scorePair(
        LookupMatcher.normalise('Acme Supplies'),
        LookupMatcher.normalise('Acme Supply'),
      ),
      greaterThan(0.5),
    );
    expect(
      FuzzyMatcher.scorePair(
        LookupMatcher.normalise('Acme Supplies'),
        LookupMatcher.normalise('Completely Different'),
      ),
      lessThan(0.4),
    );
    final List<({ReferenceRow row, double score})> ranked = FuzzyMatcher.rank(
      rows: rows,
      query: 'Acme Supply',
      column: 'name',
      threshold: 0.5,
    );
    expect(ranked.first.row.id, '1');
  });

  test('prefill skips verified fields and unlink detaches one field only', () {
    final Map<String, PrefillField> current = <String, PrefillField>{
      'supplier_name': (
        value: 'Old',
        verified: true,
        source: PrefillSource.manual,
        rowId: null,
        linked: false,
      ),
      'phone': (
        value: '',
        verified: false,
        source: PrefillSource.manual,
        rowId: null,
        linked: false,
      ),
    };
    final Map<String, PrefillField> filled = LookupPrefill.apply(
      current: current,
      fillMapping: const <String, String>{
        'name': 'supplier_name',
        'phone': 'phone',
      },
      rowValues: const <String, String>{'name': 'Acme', 'phone': '555'},
      rowId: '1',
    );
    expect(filled['supplier_name']!.value, 'Old');
    expect(filled['phone']!.value, '555');
    expect(filled['phone']!.rowId, '1');

    final Map<String, PrefillField> unlinked = LookupUnlink.editField(
      current: filled,
      fieldKey: 'phone',
      newValue: '999',
    );
    expect(unlinked['phone']!.value, '999');
    expect(unlinked['phone']!.linked, isFalse);
    expect(unlinked['phone']!.source, PrefillSource.manual);
    expect(unlinked['supplier_name']!.value, 'Old');
  });

  test('prefilled values stay after the source row changes', () {
    final Map<String, PrefillField> captured = LookupPrefill.apply(
      current: const <String, PrefillField>{},
      fillMapping: const <String, String>{'phone': 'phone'},
      rowValues: const <String, String>{'phone': '111'},
      rowId: '1',
    );
    // Source row later becomes 222 — captured map is unchanged.
    expect(captured['phone']!.value, '111');
    expect(
      LookupPrefill.apply(
        current: captured,
        fillMapping: const <String, String>{'phone': 'phone'},
        rowValues: const <String, String>{'phone': '222'},
        rowId: '1',
      )['phone']!.value,
      '222',
    );
    final Map<String, PrefillField> verified = <String, PrefillField>{
      'phone': (
        value: '111',
        verified: true,
        source: PrefillSource.lookup,
        rowId: '1',
        linked: true,
      ),
    };
    expect(
      LookupPrefill.apply(
        current: verified,
        fillMapping: const <String, String>{'phone': 'phone'},
        rowValues: const <String, String>{'phone': '222'},
        rowId: '1',
      )['phone']!.value,
      '111',
    );
  });

  test('LookupBinding refuses unknown and duplicate fill targets', () {
    expect(
      LookupBinding.validate(
        binding: const LookupBinding(
          datasetId: 'ds',
          matchColumns: <String>['code'],
          fillMapping: <String, String>{'name': 'missing'},
        ),
        templateFieldKeys: const <String>{'phone'},
      ),
      contains('Unknown'),
    );
    expect(
      LookupBinding.validate(
        binding: const LookupBinding(
          datasetId: 'ds',
          matchColumns: <String>['code'],
          fillMapping: <String, String>{'name': 'phone', 'code': 'phone'},
        ),
        templateFieldKeys: const <String>{'phone'},
      ),
      contains('more than once'),
    );
  });
}
