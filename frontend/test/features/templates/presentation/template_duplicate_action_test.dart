import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/records/domain/record_repository.dart';
import 'package:tapture/features/templates/presentation/template_duplicate_action.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_record_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets(
    'duplication copies fields, rows and aliases and copies no records',
    (WidgetTester tester) async {
      final FakeTemplateRepository templates = FakeTemplateRepository();
      final FakeRecordRepository records = FakeRecordRepository();
      addTearDown(templates.dispose);
      addTearDown(records.dispose);

      final TemplateDef original = _ok(
        await templates.save(
          aTemplate(
            id: 'template-src',
            name: 'Assets',
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'asset_tag',
                label: 'Asset tag',
                type: FieldType.text,
              ),
            ],
            identityFieldKeys: const <String>['asset_tag'],
            rows: const <TemplateRow>[
              TemplateRow(
                identifier: 'pump-1',
                label: 'Pump',
                outputRowNumber: 4,
                aliases: <String>['pump', 'water pump'],
              ),
            ],
          ),
        ),
      );
      final RecordDetail record = _ok(
        await records.save(aRecord(templateId: original.id)),
      );

      await tester.pumpWidget(
        ProviderScope(
          retry: (int _, Object _) => null,
          overrides: <Override>[
            templateRepositoryProvider.overrideWith((Ref _) => templates),
          ],
          child: MaterialApp(home: _DuplicateHost(template: original)),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(TemplateDuplicateAction));
      await tester.pump();

      expect(templates.count, 2);
      final TemplateDef copy = _present(await templates.byId('template-0'));
      expect(copy.id, isNot(original.id));
      expect(copy.name, Copy.templateCopyName(original.name));
      expect(copy.fields, original.fields);
      expect(copy.rows, original.rows);
      expect(copy.rows.single.aliases, <String>['pump', 'water pump']);
      expect(copy.identityFieldKeys, original.identityFieldKeys);
      expect(_ok(await templates.byId(original.id))!.name, 'Assets');

      expect(_ok(await records.byId(record.id))!.templateId, original.id);
      expect(copy.id, isNot(record.templateId));
    },
  );
}

class _DuplicateHost extends ConsumerWidget {
  const _DuplicateHost({required this.template});

  final TemplateDef template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TemplateDuplicateAction(template: template);
  }
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

TemplateDef _present(Result<TemplateDef?> result) {
  final TemplateDef? value = _ok(result);
  if (value == null) {
    throw TestFailure('Expected a stored template.');
  }
  return value;
}
