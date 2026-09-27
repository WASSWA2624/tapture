import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_detail_screen.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_record_repository.dart';

const String _recordId = 'r1';

const StorageFailure _unreadable = StorageFailure(
  message: 'The record could not be read.',
  recoveryAction: 'Try again in a moment.',
);

void main() {
  testWidgets('a missing record says it is gone', (WidgetTester tester) async {
    await _pump(tester);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.recordGoneHeadline), findsOneWidget);
    expect(find.text(Copy.recordGoneMessage), findsOneWidget);
  });

  testWidgets('a failed read says why and retry loads the record', (
    WidgetTester tester,
  ) async {
    final FakeRecordRepository records = await _pump(
      tester,
      record: aRecordEntry(id: _recordId, name: 'Autoclave'),
      readFailure: _unreadable,
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(_unreadable.message), findsOneWidget);
    expect(find.text(_unreadable.recoveryAction), findsOneWidget);

    records.readFailure = null;
    await tester.tap(find.text(Copy.tryAgain));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsNothing);
    expect(find.text('Autoclave'), findsWidgets);
  });

  testWidgets('every value shows its source without another tap', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      record: aRecordEntry(
        id: _recordId,
        name: 'Autoclave',
        fields: const <String, String>{'serial': 'A-1'},
        source: 'ocr',
      ),
      template: aTemplate(
        fields: const <FieldDef>[
          FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
        ],
      ),
    );

    expect(find.text('A-1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('record-source-serial')),
      findsOneWidget,
    );
    expect(find.text(Copy.recordSourceOcr), findsWidgets);
  });
}

Future<FakeRecordRepository> _pump(
  WidgetTester tester, {
  RecordEntry? record,
  TemplateDef? template,
  Failure? readFailure,
}) async {
  final FakeRecordRepository records = FakeRecordRepository();
  addTearDown(records.dispose);
  if (record != null) {
    records.seedEntry(record);
  }
  records.readFailure = readFailure;
  final FakeTemplateRepository templates = FakeTemplateRepository();
  addTearDown(templates.dispose);
  if (template != null) {
    await templates.save(template);
  }
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => records),
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const RecordDetailScreen(recordId: _recordId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return records;
}
