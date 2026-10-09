import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  for (final Object declaration in <Object>[
    'FUTURE_SOURCE', false, <String, Object?>{'provider': 'future'}, 'LOCAL_ADDRESS',
  ]) {
    test('a captured shape retains opaque $declaration and valid sibling policies through later versions', () {
      final TemplateDef first = aTemplate(version: 1, fields: <FieldDef>[
        FieldDef(fieldKey: 'address', label: 'Address', type: FieldType.number,
            validation: <String, Object?>{'_tapture': <String, Object?>{'autoFill': declaration}}),
        const FieldDef(fieldKey: 'instant', label: 'Instant', type: FieldType.text,
            autoFill: AutoFill.now),
      ]).copyWith(identityFieldKeys: const <String>['address']);
      final TemplateDef second = TemplateVersioning.remember(from: first,
          to: first.copyWith(version: 2, name: 'Renamed'));
      final TemplateDef third = TemplateVersioning.remember(from: second,
          to: second.copyWith(version: 3, name: 'Renamed again'));
      final TemplateDef captured = TemplateVersioning.shapeFor(third, 1)!;
      expect(captured.fields.first.autoFill, isNull);
      expect(captured.fields.first.validation, first.fields.first.validation);
      expect(captured.fields.last.autoFill, AutoFill.now);
      expect(captured.identityFieldKeys, <String>['address']);
      expect(TemplateVersioning.shapeFor(third, 2)!.fields.first.validation,
          first.fields.first.validation);
    });
  }
  test('unreadable full history is retained verbatim across remember and never reinterpreted as legacy fields', () {
    final Map<String, Object?> invalid = <String, Object?>{
      'schema_version': 1, 'name': 42,
      'fields': <Map<String, Object?>>[
        <String, Object?>{'fieldKey': 'serial', 'type': 'text', 'label': 'Legacy-looking'},
      ],
    };
    final TemplateDef current = aTemplate(version: 3).copyWith(detection: <String, Object?>{
      '_tapture_versions': <String, Object?>{'1': invalid, '2': 'unreadable raw', 'other': <String, Object?>{'raw': true}},
    });
    expect(TemplateVersioning.shapeFor(current, 1), isNull);
    final TemplateDef next = TemplateVersioning.remember(from: current,
        to: current.copyWith(version: 4, name: 'Edited'));
    final Map versions = next.detection['_tapture_versions']! as Map;
    expect(versions['1'], invalid);
    expect(versions['2'], 'unreadable raw');
    expect(versions['other'], <String, Object?>{'raw': true});
    expect(TemplateVersioning.shapeFor(next, 1), isNull);
    expect(TemplateVersioning.shapeFor(next, 2), isNull);
    expect(TemplateVersioning.shapeFor(next, 3)!.name, current.name);
  });
  test('malformed stored row identifiers leave full history unavailable without dropping raw metadata', () {
    final TemplateDef current = aTemplate(version: 2);
    final Map<String, Object?> invalid = <String, Object?>{
      ...TemplateJson.encode(current), '_tapture_row_ids': <String, Object?>{'serial': 42},
    };
    final TemplateDef stored = current.copyWith(detection: <String, Object?>{
      '_tapture_versions': <String, Object?>{'1': invalid},
    });
    expect(TemplateVersioning.shapeFor(stored, 1), isNull);
    final TemplateDef next = TemplateVersioning.remember(from: stored,
        to: stored.copyWith(version: 3));
    expect((next.detection['_tapture_versions']! as Map)['1'], invalid);
    expect(TemplateVersioning.shapeFor(next, 1), isNull);
  });
  test('nonpositive captured versions never resolve an imported shape', () {
    final TemplateDef current = aTemplate(version: 0);
    expect(TemplateVersioning.shapeFor(current, 0), isNull);
    expect(TemplateVersioning.shapeFor(current, -1), isNull);
  });
  test(
    'captured versions retain choice codes, units, validation and visibility across edits',
    () {
      const FieldDef original = FieldDef(
        fieldKey: 'condition',
        label: 'Condition',
        type: FieldType.choice,
        options: <Object>['good', 'bad'],
        unit: 'kg',
        helpText: 'Read the label',
        requiredWhen: 'present == true',
        hidden: true,
        validation: <String, Object?>{'min': 2},
        lookup: <String, Object?>{'datasetId': 'suppliers'},
      );
      final TemplateDef first = aTemplate(
        version: 1,
        fields: const <FieldDef>[original],
      );
      final TemplateDef second = TemplateVersioning.remember(
        from: first,
        to: first.copyWith(
          version: 2,
          fields: <FieldDef>[
            original.copyWith(
              options: <Object>['other'],
              unit: 'g',
              hidden: false,
            ),
          ],
        ),
      );
      final TemplateDef third = TemplateVersioning.remember(
        from: second,
        to: second.copyWith(version: 3, name: 'Renamed'),
      );
      expect(TemplateVersioning.shapeFor(third, 1)!.fields.single, original);
      expect(
        TemplateVersioning.shapeFor(third, 2)!.fields.single.options,
        <Object>['other'],
      );
      expect(TemplateVersioning.isStructural(first, second), isTrue);
    },
  );

  test('a behind record whose captured shape is unknown is counted and names '
      'the values a move would retire', () {
    final TemplateDef current = aTemplate(
      version: 3,
      fields: const <FieldDef>[
        FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
      ],
    );

    final TemplateVersioning preview = TemplateVersioning.preview(
      current: current,
      records: const <CapturedTemplateRecord>[
        (
          id: 'lost-1',
          templateVersion: 1,
          fields: <String, String>{'serial': 'A', 'colour': 'red'},
          retired: <String>{},
        ),
        (
          id: 'lost-2',
          templateVersion: 2,
          fields: <String, String>{'colour': 'blue', 'old': 'x'},
          retired: <String>{'old'},
        ),
        (
          id: 'current',
          templateVersion: 3,
          fields: <String, String>{'serial': 'B'},
          retired: <String>{},
        ),
      ],
    );

    expect(preview.behindCount, 2);
    expect(preview.unresolved, 2);
    expect(preview.isEmpty, isFalse);
    expect(preview.retiring, <({String fieldKey, String label, int records})>[
      (fieldKey: 'colour', label: 'colour', records: 2),
    ]);
    expect(const TemplateVersioning.none().isEmpty, isTrue);
  });

  test(
    'a record keeps its captured version and the diff matches the bump',
    () async {
      final FakeTemplateRepository templates = FakeTemplateRepository();
      addTearDown(templates.dispose);
      final TemplateDef first = _ok(
        await templates.save(
          aTemplate(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial',
                type: FieldType.text,
              ),
              FieldDef(
                fieldKey: 'extra',
                label: 'Extra',
                type: FieldType.number,
              ),
            ],
          ),
        ),
      );
      expect(first.version, 1);

      const CapturedTemplateRecord record = (
        id: 'record-1',
        templateVersion: 1,
        fields: <String, String>{'serial': 'A-1', 'extra': '3'},
        retired: <String>{},
      );

      final TemplateDef second = _ok(
        await templates.save(
          first.copyWith(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial',
                type: FieldType.number,
              ),
              FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
            ],
          ),
        ),
      );
      expect(second.version, 2);
      expect(record.templateVersion, 1);

      final TemplateDef? captured = TemplateVersioning.shapeFor(second, 1);
      expect(captured, isNotNull);
      expect(captured!.version, 1);
      expect(captured.fields.map((FieldDef field) => field.fieldKey), <String>[
        'serial',
        'extra',
      ]);
      expect(captured.fields.first.type, FieldType.text);

      final ({List<String> added, List<String> removed, List<String> retyped})
      change = TemplateVersioning.diff(captured, second);
      expect(change.added, <String>['name']);
      expect(change.removed, <String>['extra']);
      expect(change.retyped, <String>['serial']);

      final List<CapturedTemplateRecord> moved = TemplateVersioning.migrate(
        current: second,
        records: const <CapturedTemplateRecord>[record],
      );
      expect(moved.single.templateVersion, 2);
      expect(moved.single.fields['extra'], '3');
      expect(moved.single.retired, <String>{'extra'});
      expect(record.templateVersion, 1);
    },
  );

  test('a failed apply leaves every record on its captured version', () async {
    final TemplateDef from = aTemplate(
      version: 1,
      fields: const <FieldDef>[
        FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
      ],
    );
    final TemplateDef to = TemplateVersioning.remember(
      from: from,
      to: from.copyWith(
        version: 2,
        fields: const <FieldDef>[
          FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.number),
          FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
        ],
      ),
    );
    const CapturedTemplateRecord record = (
      id: 'record-1',
      templateVersion: 1,
      fields: <String, String>{'serial': 'A-1'},
      retired: <String>{},
    );
    List<CapturedTemplateRecord>? written;
    final Result<List<CapturedTemplateRecord>> result =
        await TemplateVersioning.apply(
          current: to,
          records: const <CapturedTemplateRecord>[record],
          persist: (List<CapturedTemplateRecord> next) async {
            written = next;
            return const FailureResult<void>(
              StorageFailure(
                message: 'The records could not be moved.',
                recoveryAction: 'Free space, then try again.',
              ),
            );
          },
        );
    expect(result, isA<FailureResult<List<CapturedTemplateRecord>>>());
    expect(record.templateVersion, 1);
    expect(written, isNotNull);
    expect(written!.single.templateVersion, 2);
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
