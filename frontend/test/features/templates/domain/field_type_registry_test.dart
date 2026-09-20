import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/field_type_registry.dart';

void main() {
  test('every §12.1 type is registered with all four behaviours', () {
    expect(FieldTypeRegistry.types, FieldType.values);
    expect(FieldType.values, hasLength(19));
    expect(FieldType.values, <FieldType>[
      FieldType.text,
      FieldType.longText,
      FieldType.number,
      FieldType.decimal,
      FieldType.currency,
      FieldType.percentage,
      FieldType.date,
      FieldType.time,
      FieldType.dateTime,
      FieldType.boolean,
      FieldType.choice,
      FieldType.multiChoice,
      FieldType.lookup,
      FieldType.barcode,
      FieldType.photoReference,
      FieldType.documentReference,
      FieldType.gpsLocation,
      FieldType.signature,
      FieldType.computed,
    ]);

    for (final FieldType type in FieldType.values) {
      final FieldTypeBehaviours behaviours = FieldTypeRegistry.of(type);
      final FieldDef field = _field(type);
      expect(behaviours.editor, isA<FieldEditorKind>());
      expect(behaviours.storageForm, isA<StorageForm>());
      expect(behaviours.validator(null, field), isA<Success<void>>());
      expect(() => behaviours.normaliser(null, field), returnsNormally);
    }
  });

  test('each type names the catalogue widget or a declared exception', () {
    const Map<FieldType, (FieldEditorKind, StorageForm, bool)>
    expected = <FieldType, (FieldEditorKind, StorageForm, bool)>{
      FieldType.text: (FieldEditorKind.appTextField, StorageForm.text, true),
      FieldType.longText: (
        FieldEditorKind.appTextField,
        StorageForm.text,
        true,
      ),
      FieldType.number: (
        FieldEditorKind.appNumberField,
        StorageForm.integer,
        true,
      ),
      FieldType.decimal: (
        FieldEditorKind.appNumberField,
        StorageForm.decimal,
        true,
      ),
      FieldType.currency: (
        FieldEditorKind.appNumberField,
        StorageForm.decimal,
        true,
      ),
      FieldType.percentage: (
        FieldEditorKind.appNumberField,
        StorageForm.decimal,
        true,
      ),
      FieldType.date: (FieldEditorKind.appDateField, StorageForm.date, true),
      FieldType.time: (FieldEditorKind.appDateField, StorageForm.time, true),
      FieldType.dateTime: (
        FieldEditorKind.appDateField,
        StorageForm.dateTime,
        true,
      ),
      FieldType.boolean: (
        FieldEditorKind.appSwitchTile,
        StorageForm.boolean,
        true,
      ),
      FieldType.choice: (
        FieldEditorKind.appChoiceField,
        StorageForm.choice,
        true,
      ),
      FieldType.multiChoice: (
        FieldEditorKind.appMultiChoiceField,
        StorageForm.multiChoice,
        true,
      ),
      FieldType.lookup: (
        FieldEditorKind.appChoiceField,
        StorageForm.lookupKey,
        true,
      ),
      FieldType.barcode: (FieldEditorKind.appTextField, StorageForm.text, true),
      FieldType.photoReference: (
        FieldEditorKind.appTextField,
        StorageForm.pathList,
        true,
      ),
      FieldType.documentReference: (
        FieldEditorKind.appTextField,
        StorageForm.pathList,
        true,
      ),
      FieldType.gpsLocation: (
        FieldEditorKind.gpsStamp,
        StorageForm.geoPoint,
        false,
      ),
      FieldType.signature: (
        FieldEditorKind.signaturePad,
        StorageForm.imagePath,
        false,
      ),
      FieldType.computed: (
        FieldEditorKind.computedReadOnly,
        StorageForm.computed,
        false,
      ),
    };

    expect(expected.keys.toSet(), FieldType.values.toSet());

    for (final MapEntry<FieldType, (FieldEditorKind, StorageForm, bool)> entry
        in expected.entries) {
      final FieldTypeBehaviours behaviours = FieldTypeRegistry.of(entry.key);
      expect(behaviours.editor, entry.value.$1);
      expect(behaviours.storageForm, entry.value.$2);
      expect(FieldTypeRegistry.usesCatalogueEditor(entry.key), entry.value.$3);
      expect(behaviours.editor.usesCatalogue, entry.value.$3);
      if (entry.value.$3) {
        expect(behaviours.editor.catalogueWidget, isNotNull);
        expect(behaviours.editor.catalogueWidget, startsWith('App'));
      } else {
        expect(behaviours.editor.catalogueWidget, isNull);
      }
    }
  });

  test('presentation supplies the editor builder; domain builds nothing', () {
    final List<FieldEditorKind> requested = <FieldEditorKind>[];
    final Map<FieldEditorKind, FieldEditorBuilder<String>> builders =
        <FieldEditorKind, FieldEditorBuilder<String>>{
          for (final FieldEditorKind kind in FieldEditorKind.values)
            kind:
                ({
                  required FieldDef field,
                  required Object? value,
                  required void Function(Object? value) onChanged,
                }) {
                  requested.add(kind);
                  onChanged(value);
                  return '${field.type.name}:${kind.name}';
                },
        };

    for (final FieldType type in FieldType.values) {
      final Result<String> built = FieldTypeRegistry.editor(
        type: type,
        builders: builders,
        field: _field(type),
        value: null,
        onChanged: (Object? _) {},
      );
      expect(built, isA<Success<String>>());
      expect(
        built.getOrElse(() => ''),
        '${type.name}:${FieldTypeRegistry.of(type).editor.name}',
      );
    }

    expect(
      FieldTypeRegistry.editor(
        type: FieldType.text,
        builders: <FieldEditorKind, FieldEditorBuilder<String>>{},
        field: _field(FieldType.text),
        value: null,
        onChanged: (Object? _) {},
      ),
      isA<FailureResult<String>>(),
    );

    final String source = File(
      'lib/features/templates/domain/field_type_registry.dart',
    ).readAsStringSync();
    expect(source.contains('package:flutter'), isFalse);
  });

  test('validators and normalisers coerce each type without guessing', () {
    expect(_ok(FieldType.text, '  serial  '), 'serial');
    expect(_fail(FieldType.text, 12), isTrue);
    expect(_failedValue(FieldType.text, 'ab', _textLength), isTrue);

    expect(_ok(FieldType.number, '12'), 12);
    expect(_ok(FieldType.number, 12.0), 12);
    expect(_fail(FieldType.number, '12.5'), isTrue);
    expect(
      _failedValue(
        FieldType.number,
        3,
        const FieldDef(
          fieldKey: 'k',
          label: 'L',
          type: FieldType.number,
          validation: <String, Object?>{'min': 10},
        ),
      ),
      isTrue,
    );

    expect(_ok(FieldType.decimal, '1.5'), 1.5);
    expect(_ok(FieldType.currency, 2), 2);
    expect(_ok(FieldType.percentage, '40'), 40);
    expect(_fail(FieldType.decimal, 'x'), isTrue);

    expect(_ok(FieldType.date, '2026-09-20'), DateTime(2026, 9, 20));
    expect(_fail(FieldType.date, '2026-13-40'), isTrue);
    expect(_ok(FieldType.time, '8:05:00'), '08:05:00');
    expect(_fail(FieldType.time, '25:00'), isTrue);
    expect(
      _ok(FieldType.dateTime, '2026-09-20T08:05:00.000'),
      DateTime(2026, 9, 20, 8, 5),
    );

    expect(_ok(FieldType.boolean, 'yes'), isTrue);
    expect(_ok(FieldType.boolean, '0'), isFalse);
    expect(_fail(FieldType.boolean, 'maybe'), isTrue);

    const FieldDef status = FieldDef(
      fieldKey: 'status',
      label: 'Status',
      type: FieldType.choice,
      options: <Object>[
        <String, Object?>{'code': 'ok', 'label': 'Serviceable'},
      ],
    );
    expect(_ok(FieldType.choice, 'Serviceable', status), 'ok');
    expect(_failedValue(FieldType.choice, 'broken', status), isTrue);

    const FieldDef tags = FieldDef(
      fieldKey: 'tags',
      label: 'Tags',
      type: FieldType.multiChoice,
      options: <Object>['red', 'blue'],
    );
    expect(_ok(FieldType.multiChoice, <String>['Red', 'blue'], tags), <String>[
      'red',
      'blue',
    ]);

    expect(_ok(FieldType.lookup, 'asset-1'), 'asset-1');
    expect(_ok(FieldType.barcode, '  123  '), '123');
    expect(_ok(FieldType.photoReference, 'a.jpg'), <String>['a.jpg']);
    expect(_ok(FieldType.documentReference, <String>['a.pdf']), <String>[
      'a.pdf',
    ]);
    expect(_fail(FieldType.photoReference, 1), isTrue);

    expect(
      _ok(FieldType.gpsLocation, <String, Object?>{
        'latitude': 1.5,
        'longitude': 2.25,
        'accuracy': 4,
      }),
      <String, double>{'latitude': 1.5, 'longitude': 2.25, 'accuracy': 4},
    );
    expect(
      _fail(FieldType.gpsLocation, <String, Object?>{
        'latitude': 100,
        'longitude': 0,
      }),
      isTrue,
    );

    expect(_ok(FieldType.signature, '  sig.png  '), 'sig.png');
    expect(_ok(FieldType.computed, 42), 42);
    expect(
      FieldTypeRegistry.validate(
        type: FieldType.computed,
        value: null,
        field: _field(FieldType.computed),
      ),
      isA<Success<void>>(),
    );
  });
}

const FieldDef _textLength = FieldDef(
  fieldKey: 'k',
  label: 'L',
  type: FieldType.text,
  validation: <String, Object?>{'minLength': 3},
);

FieldDef _field(FieldType type) {
  return FieldDef(fieldKey: 'k', label: 'L', type: type);
}

Object? _ok(FieldType type, Object? value, [FieldDef? field]) {
  final FieldDef def = field ?? _field(type);
  final Result<void> result = FieldTypeRegistry.validate(
    type: type,
    value: value,
    field: def,
  );
  expect(result, isA<Success<void>>());
  return FieldTypeRegistry.normalise(type: type, value: value, field: def);
}

bool _fail(FieldType type, Object? value) {
  return _failedValue(type, value, _field(type));
}

bool _failedValue(FieldType type, Object? value, FieldDef field) {
  final Result<void> result = FieldTypeRegistry.validate(
    type: type,
    value: value,
    field: field,
  );
  return result is FailureResult<void> && result.failure is ValidationFailure;
}
