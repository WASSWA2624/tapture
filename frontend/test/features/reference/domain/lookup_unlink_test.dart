import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/reference/domain/lookup_prefill.dart';
import 'package:tapture/features/reference/domain/lookup_unlink.dart';

Map<String, PrefillField> _prefilled() {
  return LookupPrefill.apply(
    current: const <String, PrefillField>{},
    fillMapping: const <String, String>{
      'name': 'supplier_name',
      'phone': 'supplier_phone',
      'country': 'supplier_country',
    },
    rowValues: const <String, String>{
      'name': 'Acme Supplies',
      'phone': '0700 000000',
      'country': 'UG',
    },
    rowId: 'row-1',
  );
}

void main() {
  test('editing the phone number does not detach the supplier name', () {
    final Map<String, PrefillField> before = _prefilled();
    final Map<String, PrefillField> after = LookupUnlink.editField(
      current: before,
      fieldKey: 'supplier_phone',
      newValue: '0711 111111',
    );
    expect(after['supplier_name'], before['supplier_name']);
    expect(after['supplier_country'], before['supplier_country']);
    expect(after['supplier_name']!.linked, isTrue);
    expect(after['supplier_name']!.rowId, 'row-1');
    expect(after['supplier_name']!.source, PrefillSource.lookup);
  });

  test(
    'the edited field alone becomes a verified manual value with no row',
    () {
      final Map<String, PrefillField> after = LookupUnlink.editField(
        current: _prefilled(),
        fieldKey: 'supplier_phone',
        newValue: '0711 111111',
      );
      expect(after['supplier_phone'], (
        value: '0711 111111',
        verified: true,
        source: PrefillSource.manual,
        rowId: null,
        linked: false,
      ));
      expect(
        after.values.where((PrefillField field) => field.linked),
        hasLength(2),
      );
    },
  );

  test('editing a field the record does not have adds an unverified manual '
      'value', () {
    final Map<String, PrefillField> after = LookupUnlink.editField(
      current: _prefilled(),
      fieldKey: 'notes',
      newValue: 'Gate B',
    );
    expect(after['notes'], (
      value: 'Gate B',
      verified: false,
      source: PrefillSource.manual,
      rowId: null,
      linked: false,
    ));
    expect(after.length, 4);
  });

  test('the input map is left as it was', () {
    final Map<String, PrefillField> before = _prefilled();
    LookupUnlink.editField(
      current: before,
      fieldKey: 'supplier_phone',
      newValue: '0711 111111',
    );
    expect(before['supplier_phone']!.value, '0700 000000');
    expect(before['supplier_phone']!.linked, isTrue);
  });
}
