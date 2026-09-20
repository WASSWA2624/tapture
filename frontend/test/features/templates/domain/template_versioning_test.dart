import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../fakes/fake_template_repository.dart';

void main() {
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
