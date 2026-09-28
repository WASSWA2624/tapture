import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/reference/domain/lookup_prefill.dart';

const PrefillField _blank = (
  value: '',
  verified: false,
  source: PrefillSource.manual,
  rowId: null,
  linked: false,
);

const Map<String, String> _mapping = <String, String>{
  'name': 'supplier_name',
  'phone': 'supplier_phone',
};

const Map<String, String> _acme = <String, String>{
  'code': 'ACME',
  'name': 'Acme Supplies',
  'phone': '0700 000000',
};

void main() {
  test('an unverified field takes the row value with lookup provenance', () {
    final Map<String, PrefillField> filled = LookupPrefill.apply(
      current: const <String, PrefillField>{
        'supplier_name': _blank,
        'supplier_phone': _blank,
      },
      fillMapping: _mapping,
      rowValues: _acme,
      rowId: 'row-1',
    );
    expect(filled['supplier_name'], (
      value: 'Acme Supplies',
      verified: false,
      source: PrefillSource.lookup,
      rowId: 'row-1',
      linked: true,
    ));
    expect(filled['supplier_phone']!.value, '0700 000000');
    expect(filled['supplier_phone']!.rowId, 'row-1');
  });

  test('a verified field is left alone while its siblings are filled', () {
    const PrefillField verified = (
      value: 'Typed by hand',
      verified: true,
      source: PrefillSource.manual,
      rowId: null,
      linked: false,
    );
    final Map<String, PrefillField> filled = LookupPrefill.apply(
      current: const <String, PrefillField>{
        'supplier_name': verified,
        'supplier_phone': _blank,
      },
      fillMapping: _mapping,
      rowValues: _acme,
      rowId: 'row-1',
    );
    expect(filled['supplier_name'], verified);
    expect(filled['supplier_phone']!.value, '0700 000000');
    expect(filled['supplier_phone']!.source, PrefillSource.lookup);
  });

  test('a field the record does not have yet is created by the fill', () {
    final Map<String, PrefillField> filled = LookupPrefill.apply(
      current: const <String, PrefillField>{},
      fillMapping: _mapping,
      rowValues: _acme,
      rowId: 'row-1',
    );
    expect(
      filled.keys,
      unorderedEquals(<String>['supplier_name', 'supplier_phone']),
    );
    expect(filled['supplier_name']!.linked, isTrue);
  });

  test('a column the row lacks fills its field as empty, still linked', () {
    final Map<String, PrefillField> filled = LookupPrefill.apply(
      current: const <String, PrefillField>{},
      fillMapping: _mapping,
      rowValues: const <String, String>{'code': 'ACME', 'name': 'Acme'},
      rowId: 'row-1',
    );
    expect(filled['supplier_phone']!.value, '');
    expect(filled['supplier_phone']!.linked, isTrue);
    expect(filled['supplier_phone']!.rowId, 'row-1');
  });

  test('fields outside the mapping and the input map are untouched', () {
    const PrefillField serial = (
      value: 'SN-9',
      verified: false,
      source: PrefillSource.manual,
      rowId: null,
      linked: false,
    );
    final Map<String, PrefillField> current = <String, PrefillField>{
      'serial': serial,
      'supplier_name': _blank,
    };
    final Map<String, PrefillField> filled = LookupPrefill.apply(
      current: current,
      fillMapping: _mapping,
      rowValues: _acme,
      rowId: 'row-1',
    );
    expect(filled['serial'], serial);
    expect(current['supplier_name'], _blank);
    expect(current.containsKey('supplier_phone'), isFalse);
  });

  test('an already-prefilled record keeps its captured value after its source '
      'row changes', () {
    final Map<String, PrefillField> captured = LookupPrefill.apply(
      current: const <String, PrefillField>{},
      fillMapping: const <String, String>{'phone': 'supplier_phone'},
      rowValues: const <String, String>{'phone': '111'},
      rowId: 'row-1',
    );
    final Map<String, String> row = <String, String>{'phone': '111'};
    row['phone'] = '222';
    expect(captured['supplier_phone']!.value, '111');
    expect(captured['supplier_phone']!.rowId, 'row-1');
  });

  test('re-running the lookup on purpose refreshes an unverified value and '
      'still leaves a verified one alone', () {
    final Map<String, PrefillField> captured = LookupPrefill.apply(
      current: const <String, PrefillField>{},
      fillMapping: const <String, String>{'phone': 'supplier_phone'},
      rowValues: const <String, String>{'phone': '111'},
      rowId: 'row-1',
    );
    final Map<String, PrefillField> refreshed = LookupPrefill.apply(
      current: captured,
      fillMapping: const <String, String>{'phone': 'supplier_phone'},
      rowValues: const <String, String>{'phone': '222'},
      rowId: 'row-1',
    );
    expect(refreshed['supplier_phone']!.value, '222');

    final Map<String, PrefillField> verified = <String, PrefillField>{
      'supplier_phone': (
        value: '111',
        verified: true,
        source: PrefillSource.lookup,
        rowId: 'row-1',
        linked: true,
      ),
    };
    expect(
      LookupPrefill.apply(
        current: verified,
        fillMapping: const <String, String>{'phone': 'supplier_phone'},
        rowValues: const <String, String>{'phone': '222'},
        rowId: 'row-1',
      )['supplier_phone']!.value,
      '111',
    );
  });
}
