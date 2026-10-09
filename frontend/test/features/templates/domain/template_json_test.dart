import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/domain/template_json.dart';

import '../../../support/factories.dart';

void main() {
  for (final ({Object? top, Object nested}) declarations
      in <({Object? top, Object nested})>[
        (
          top: <String, Object?>{
            'provider': 'top',
            'raw': <Object?>[1, null],
          },
          nested: <String, Object?>{
            'provider': 'nested',
            'raw': <Object?>[false, null],
          },
        ),
        (top: 'NOW', nested: 'FUTURE_SOURCE'),
        (top: null, nested: 42),
      ]) {
    test(
      'distinct stored top and nested sources ${declarations.top}/${declarations.nested} survive exact roundtrips',
      () {
        final Map<String, Object?> raw = _sourcePayload(
          declarations.nested,
          carried: true,
        );
        ((raw['fields']! as List).first as Map)['auto_fill'] = declarations.top;
        expect(
          TemplateJson.decode(raw, projectId: 'p'),
          isA<FailureResult<TemplateDef>>(),
        );
        final TemplateDef stored =
            (TemplateJson.decodeStoredShape(raw, projectId: 'p')
                    as Success<TemplateDef>)
                .value;
        expect(stored.fields.first.autoFill, isNull);
        expect(stored.fields.first.validation['_tapture'], <String, Object?>{
          'autoFill': declarations.nested,
          'autoFillTop': declarations.top,
        });
        final Map<String, Object?> encoded = TemplateJson.encode(stored);
        expect(
          (encoded['fields']! as List).first,
          containsPair('auto_fill', declarations.top),
        );
        expect(
          (TemplateJson.decodeStoredShape(encoded, projectId: 'p')
                  as Success<TemplateDef>)
              .value
              .fields,
          stored.fields,
        );
        expect(
          TemplateJson.decode(encoded, projectId: 'p'),
          isA<FailureResult<TemplateDef>>(),
        );
      },
    );
  }
  test(
    'companion-only unsupported storage is normalized unavailable and cannot import',
    () {
      final Map<String, Object?> raw = _sourcePayload('NOW');
      ((raw['fields']! as List).first as Map)['validation'] = <String, Object?>{
        '_tapture': <String, Object?>{
          'autoFillTop': <Object?>['future', null],
        },
      };
      expect(
        TemplateJson.decode(raw, projectId: 'p'),
        isA<FailureResult<TemplateDef>>(),
      );
      final TemplateDef stored =
          (TemplateJson.decodeStoredShape(raw, projectId: 'p')
                  as Success<TemplateDef>)
              .value;
      expect(stored.fields.first.autoFill, isNull);
      expect(stored.fields.first.validation['_tapture'], <String, Object?>{
        'autoFill': <Object?>['future', null],
      });
    },
  );
  for (final AutoFill source in AutoFill.values) {
    test('the ${source.name} source keeps its token through strict JSON', () {
      final TemplateDef original = aTemplate(
        fields: <FieldDef>[
          FieldDef(
            fieldKey: 'address',
            label: 'Address',
            type: FieldType.text,
            autoFill: source,
          ),
        ],
      );
      final Map<String, Object?> encoded = TemplateJson.encode(original);
      final TemplateDef imported =
          (TemplateJson.decode(encoded, projectId: 'other')
                  as Success<TemplateDef>)
              .value;
      expect(imported.fields.single.autoFill, source);
      expect(TemplateJson.encode(imported)['fields'], encoded['fields']);
      if (source == AutoFill.localAddress) {
        expect(
          (encoded['fields']! as List).single,
          containsPair('auto_fill', 'LOCAL_ADDRESS'),
        );
      }
    });
  }

  for (final FieldType type in FieldType.values.where(
    (FieldType type) => type != FieldType.text,
  )) {
    test(
      'a $type local address is rejected for import but retained unavailable in storage',
      () {
        final Map<String, Object?> raw = _sourcePayload(
          'LOCAL_ADDRESS',
          type: type,
        );
        final Result<TemplateDef> imported = TemplateJson.decode(
          raw,
          projectId: 'p',
        );
        expect(
          imported,
          isA<FailureResult<TemplateDef>>().having(
            (FailureResult<TemplateDef> value) => value.failure.message,
            'message',
            Copy.fieldSourceAddressNeedsText,
          ),
        );
        final TemplateDef stored =
            (TemplateJson.decodeStoredShape(raw, projectId: 'p')
                    as Success<TemplateDef>)
                .value;
        expect(stored.fields.first.autoFill, isNull);
        expect(stored.fields.first.type, type);
        expect(stored.fields.first.validation, <String, Object?>{
          'minLength': 2,
          '_tapture': <String, Object?>{'autoFill': 'LOCAL_ADDRESS'},
        });
        expect(stored.fields.last.autoFill, AutoFill.now);
        expect(stored.identityFieldKeys, <String>['address']);
        expect(
          (TemplateJson.encode(stored)['fields']! as List).first,
          containsPair('auto_fill', 'LOCAL_ADDRESS'),
        );
      },
    );
  }

  for (final Object declaration in <Object>[
    'FUTURE_SOURCE',
    42,
    false,
    <String, Object?>{
      'provider': 'future',
      'settings': <Object?>[1, null, 'raw'],
    },
    <Object>['future', 3],
  ]) {
    for (final bool carried in <bool>[false, true]) {
      test(
        'unsupported $declaration from ${carried ? 'nested metadata' : 'top-level JSON'} survives stored decoding but cannot import',
        () {
          final Map<String, Object?> raw = _sourcePayload(
            declaration,
            carried: carried,
          );
          expect(
            TemplateJson.decode(raw, projectId: 'p'),
            isA<FailureResult<TemplateDef>>(),
          );
          final TemplateDef stored =
              (TemplateJson.decodeStoredShape(raw, projectId: 'p')
                      as Success<TemplateDef>)
                  .value;
          expect(stored.fields.first.autoFill, isNull);
          expect(stored.fields.first.validation, <String, Object?>{
            'minLength': 2,
            '_tapture': <String, Object?>{'autoFill': declaration},
          });
          expect(stored.fields.last.autoFill, AutoFill.now);
          final Map<String, Object?> encoded = TemplateJson.encode(stored);
          expect(
            (encoded['fields']! as List).first,
            containsPair('auto_fill', declaration),
          );
          expect(
            (TemplateJson.decodeStoredShape(encoded, projectId: 'p')
                    as Success<TemplateDef>)
                .value
                .fields,
            stored.fields,
          );
          expect(
            TemplateJson.decode(encoded, projectId: 'p'),
            isA<FailureResult<TemplateDef>>(),
          );
        },
      );
    }
  }

  test(
    'a known top-level source cannot conceal unsupported nested metadata',
    () {
      final Map<String, Object?> raw = _sourcePayload(
        'FUTURE_SOURCE',
        carried: true,
      );
      ((raw['fields']! as List).first as Map)['auto_fill'] = 'NOW';
      expect(
        TemplateJson.decode(raw, projectId: 'p'),
        isA<FailureResult<TemplateDef>>(),
      );
      final TemplateDef stored =
          (TemplateJson.decodeStoredShape(raw, projectId: 'p')
                  as Success<TemplateDef>)
              .value;
      expect(stored.fields.first.autoFill, isNull);
      expect(stored.fields.first.validation['_tapture'], <String, Object?>{
        'autoFill': 'FUTURE_SOURCE',
        'autoFillTop': 'NOW',
      });
    },
  );

  for (final Map<String, Object?> corruption in <Map<String, Object?>>[
    <String, Object?>{'type': 'unknown'},
    <String, Object?>{'hidden': 'yes'},
    <String, Object?>{'required': 'sometimes'},
    <String, Object?>{'validation': 42},
  ]) {
    test(
      'stored source compatibility does not accept structural corruption $corruption',
      () {
        final Map<String, Object?> raw = _sourcePayload('FUTURE_SOURCE');
        ((raw['fields']! as List).first as Map).addAll(corruption);
        expect(
          TemplateJson.decodeStoredShape(raw, projectId: 'p'),
          isA<FailureResult<TemplateDef>>(),
        );
        expect(
          TemplateJson.decode(raw, projectId: 'p'),
          isA<FailureResult<TemplateDef>>(),
        );
      },
    );
  }

  test(
    'the shared codec creates a new template without copying migration history',
    () {
      final TemplateDef source = aTemplate().copyWith(
        detection: const <String, Object?>{
          '_tapture_versions': <String, Object?>{'1': <String, Object?>{}},
          'kind': 'asset',
        },
      );
      final Result<TemplateDef> result = TemplateJson.decode(
        TemplateJson.encode(source),
        projectId: 'another-project',
      );
      expect(result, isA<Success<TemplateDef>>());
      final TemplateDef decoded = (result as Success<TemplateDef>).value;
      expect(decoded.id, isEmpty);
      expect(decoded.version, 1);
      expect(decoded.projectId, 'another-project');
      expect(decoded.fields, source.fields);
      expect(decoded.detection, <String, Object?>{'kind': 'asset'});
    },
  );

  group('an imported lookup', () {
    TemplateDef bound(Map<String, Object?> lookup) {
      return aTemplate(
        fields: <FieldDef>[
          FieldDef(
            fieldKey: 'supplier',
            label: 'Supplier',
            type: FieldType.lookup,
            lookup: lookup,
          ),
          const FieldDef(
            fieldKey: 'supplier_phone',
            label: 'Phone',
            type: FieldType.text,
          ),
        ],
      );
    }

    Result<TemplateDef> decode(Map<String, Object?> lookup) {
      return TemplateJson.decode(
        TemplateJson.encode(bound(lookup)),
        projectId: 'p',
      );
    }

    test('with a duplicate target is rejected', () {
      final Result<TemplateDef> result = decode(<String, Object?>{
        'datasetId': 'suppliers',
        'fillMapping': <String, String>{
          'phone': 'supplier_phone',
          'mobile': 'supplier_phone',
        },
      });

      expect(
        result,
        isA<FailureResult<TemplateDef>>().having(
          (FailureResult<TemplateDef> failed) => failed.failure.message,
          'message',
          Copy.lookupTargetTwice('supplier_phone'),
        ),
      );
    });

    test('filling a field the template does not define is rejected', () {
      final Result<TemplateDef> result = decode(<String, Object?>{
        'dataset': 'suppliers',
        'fills': <String, String>{'supplier_country': 'country'},
      });

      expect(
        result,
        isA<FailureResult<TemplateDef>>().having(
          (FailureResult<TemplateDef> failed) => failed.failure.message,
          'message',
          Copy.lookupUnknownTarget('supplier_country'),
        ),
      );
    });

    test('whose targets the template defines imports unchanged', () {
      const Map<String, Object?> lookup = <String, Object?>{
        'dataset': 'suppliers',
        'fills': <String, String>{'supplier_phone': 'phone'},
      };

      final Result<TemplateDef> result = decode(lookup);

      expect(result, isA<Success<TemplateDef>>());
      expect(
        (result as Success<TemplateDef>).value.fields.first.lookup,
        lookup,
      );
    });
  });
}

Map<String, Object?> _sourcePayload(
  Object declaration, {
  FieldType type = FieldType.text,
  bool carried = false,
}) {
  final Map<String, Object?> raw = TemplateJson.encode(
    aTemplate(
      fields: <FieldDef>[
        FieldDef(
          fieldKey: 'address',
          label: 'Address',
          type: type,
          validation: const <String, Object?>{'minLength': 2},
        ),
        const FieldDef(
          fieldKey: 'instant',
          label: 'Instant',
          type: FieldType.text,
          autoFill: AutoFill.now,
        ),
      ],
    ).copyWith(identityFieldKeys: const <String>['address']),
  );
  final Map<String, Object?> field =
      (raw['fields']! as List).first as Map<String, Object?>;
  if (carried) {
    field.remove('auto_fill');
    field['validation'] = <String, Object?>{
      'minLength': 2,
      '_tapture': <String, Object?>{'autoFill': declaration},
    };
  } else {
    field['auto_fill'] = declaration;
  }
  return raw;
}
