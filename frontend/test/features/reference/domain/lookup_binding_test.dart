import 'package:tapture/features/reference/domain/lookup_binding.dart';
import 'package:test/test.dart';

/// The supplier lookup of §16.2 in the contract's shape: `fillMapping`
/// runs dataset column → template field, the inverse of the example's
/// `fills` block.
const LookupBinding _supplier = LookupBinding(
  datasetId: 'suppliers',
  matchColumns: <String>['supplier_id', 'supplier_name'],
  fillMapping: <String, String>{
    'supplier_name': 'supplier_name',
    'contact': 'supplier_contact',
    'phone': 'supplier_phone',
    'country': 'supplier_country',
  },
  fuzzyEnabled: true,
  onNoMatch: NoMatchBehaviour.promptAddRow,
);

const Map<String, Object?> _supplierMap = <String, Object?>{
  'datasetId': 'suppliers',
  'matchColumns': <String>['supplier_id', 'supplier_name'],
  'fillMapping': <String, String>{
    'supplier_name': 'supplier_name',
    'contact': 'supplier_contact',
    'phone': 'supplier_phone',
    'country': 'supplier_country',
  },
  'fuzzyEnabled': true,
  'fuzzyThreshold': 0.8,
  'onNoMatch': 'promptAddRow',
};

const Set<String> _equipmentFields = <String>{
  'supplier',
  'supplier_name',
  'supplier_contact',
  'supplier_phone',
  'supplier_country',
  'serial',
};

void main() {
  group('specification example', () {
    test('the supplier binding round-trips through the lookup attribute', () {
      expect(_supplier.toMap(), _supplierMap);
      expect(LookupBinding.fromMap(_supplierMap), _supplier);
      expect(LookupBinding.fromMap(_supplier.toMap()), _supplier);
    });

    test('it matches on the key first, then the name, fuzzy allowed', () {
      final LookupBinding read = LookupBinding.fromMap(_supplierMap)!;
      expect(read.datasetId, 'suppliers');
      expect(read.matchColumns, <String>['supplier_id', 'supplier_name']);
      expect(read.fuzzyEnabled, isTrue);
      expect(read.fuzzyThreshold, 0.8);
      expect(read.onNoMatch, NoMatchBehaviour.promptAddRow);
      expect(read.fillMapping, hasLength(4));
    });

    test('it is accepted against the template that defines its targets', () {
      expect(
        LookupBinding.validate(
          binding: _supplier,
          templateFieldKeys: _equipmentFields,
        ),
        isNull,
      );
    });
  });

  group('reading a stored attribute', () {
    test('an empty map or one without a dataset id is no binding', () {
      expect(LookupBinding.fromMap(const <String, Object?>{}), isNull);
      expect(
        LookupBinding.fromMap(const <String, Object?>{
          'matchColumns': <String>['code'],
        }),
        isNull,
      );
      expect(
        LookupBinding.fromMap(const <String, Object?>{'datasetId': ''}),
        isNull,
      );
      expect(
        LookupBinding.fromMap(const <String, Object?>{'datasetId': 42}),
        isNull,
      );
    });

    test('values of the wrong type are dropped and defaults fill the gaps', () {
      final LookupBinding read = LookupBinding.fromMap(const <String, Object?>{
        'datasetId': 'ds',
        'matchColumns': <Object?>[1, 'code', null, 'name'],
        'fillMapping': <Object?, Object?>{'name': 1, 'phone': 'p', 3: 'x'},
        'fuzzyEnabled': 'yes',
        'fuzzyThreshold': 'high',
        'onNoMatch': 'explode',
      })!;
      expect(read.matchColumns, <String>['code', 'name']);
      expect(read.fillMapping, <String, String>{'phone': 'p'});
      expect(read.fuzzyEnabled, isFalse);
      expect(read.fuzzyThreshold, 0.8);
      expect(read.onNoMatch, NoMatchBehaviour.leaveEmpty);
    });

    test('a whole-number threshold and every behaviour name are read', () {
      final LookupBinding read = LookupBinding.fromMap(const <String, Object?>{
        'datasetId': 'ds',
        'fuzzyThreshold': 1,
        'onNoMatch': 'warn',
      })!;
      expect(read.fuzzyThreshold, 1.0);
      expect(read.onNoMatch, NoMatchBehaviour.warn);
      expect(read.matchColumns, isEmpty);
      expect(read.fillMapping, isEmpty);
    });
  });

  group('validate', () {
    test('a mapping that fills a field the template does not define is '
        'refused', () {
      expect(
        LookupBinding.validate(
          binding: const LookupBinding(
            datasetId: 'ds',
            matchColumns: <String>['code'],
            fillMapping: <String, String>{'name': 'missing'},
          ),
          templateFieldKeys: const <String>{'phone'},
        ),
        'Unknown fill target "missing".',
      );
    });

    test('two dataset columns filling one field are refused', () {
      expect(
        LookupBinding.validate(
          binding: const LookupBinding(
            datasetId: 'ds',
            matchColumns: <String>['code'],
            fillMapping: <String, String>{'name': 'phone', 'code': 'phone'},
          ),
          templateFieldKeys: const <String>{'phone'},
        ),
        'Fill target "phone" is mapped more than once.',
      );
    });

    test('distinct targets the template defines pass, as does no mapping', () {
      expect(
        LookupBinding.validate(
          binding: const LookupBinding(
            datasetId: 'ds',
            matchColumns: <String>['code'],
            fillMapping: <String, String>{'name': 'phone', 'code': 'serial'},
          ),
          templateFieldKeys: const <String>{'phone', 'serial'},
        ),
        isNull,
      );
      expect(
        LookupBinding.validate(
          binding: const LookupBinding(
            datasetId: 'ds',
            matchColumns: <String>['code'],
            fillMapping: <String, String>{},
          ),
          templateFieldKeys: const <String>{},
        ),
        isNull,
      );
    });
  });

  group('equality', () {
    test('two bindings read from the same attribute are equal and hash '
        'alike', () {
      final LookupBinding a = LookupBinding.fromMap(_supplierMap)!;
      final LookupBinding b = LookupBinding.fromMap(_supplierMap)!;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('match column order, threshold and behaviour all tell bindings '
        'apart', () {
      expect(
        _supplier,
        isNot(
          const LookupBinding(
            datasetId: 'suppliers',
            matchColumns: <String>['supplier_name', 'supplier_id'],
            fillMapping: <String, String>{
              'supplier_name': 'supplier_name',
              'contact': 'supplier_contact',
              'phone': 'supplier_phone',
              'country': 'supplier_country',
            },
            fuzzyEnabled: true,
            onNoMatch: NoMatchBehaviour.promptAddRow,
          ),
        ),
      );
      expect(
        LookupBinding.fromMap(<String, Object?>{
          ..._supplierMap,
          'fuzzyThreshold': 0.9,
        }),
        isNot(_supplier),
      );
      expect(
        LookupBinding.fromMap(<String, Object?>{
          ..._supplierMap,
          'onNoMatch': 'warn',
        }),
        isNot(_supplier),
      );
    });
  });
}
