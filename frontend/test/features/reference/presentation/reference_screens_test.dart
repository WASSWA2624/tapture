import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/reference/presentation/dataset_add_row_sheet.dart';
import 'package:tapture/features/reference/presentation/dataset_browser_screen.dart';
import 'package:tapture/features/reference/presentation/dataset_key_screen.dart';
import 'package:tapture/features/reference/presentation/dataset_row_edit_screen.dart';
import 'package:tapture/features/reference/presentation/lookup_picker_sheet.dart';
import 'package:tapture/features/reference/reference.dart';

import '../../../support/fakes/fake_reference_repository.dart';

void main() {
  late FakeReferenceRepository repo;

  setUp(() {
    repo = FakeReferenceRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: <Override>[
        referenceRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('dataset_key_screen empty and failure and non-unique key', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const DatasetKeyScreen()));
    expect(find.text(Copy.datasetsEmptyHeadline), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        const DatasetKeyScreen(
          failure: StorageFailure(message: 'boom', recoveryAction: 'retry'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('boom'), findsWidgets);

    final DatasetImportDraft draft = (
      dataset: ReferenceDataset(
        id: '',
        name: 'Parts',
        keyColumn: 'code',
        columns: const <String>['code', 'name'],
        source: DatasetSource.csv,
        importedAt: DateTime.utc(2026, 9, 22),
        rowCount: 2,
        sourceFile: 'parts.csv',
      ),
      rows: const <ReferenceRow>[
        ReferenceRow(
          id: '',
          datasetId: '',
          key: 'A',
          values: <String, String>{'code': 'A', 'name': 'One'},
        ),
        ReferenceRow(
          id: '',
          datasetId: '',
          key: 'A',
          values: <String, String>{'code': 'A', 'name': 'Two'},
        ),
      ],
      duplicateCounts: const <String, int>{'code': 1, 'name': 0},
      samples: const <String, List<String>>{
        'code': <String>['A', 'A'],
        'name': <String>['One', 'Two'],
      },
    );
    await tester.pumpWidget(wrap(DatasetKeyScreen(draft: draft)));
    await tester.pumpAndSettle();
    expect(find.text(Copy.datasetsAllowDuplicates), findsWidgets);
  });

  testWidgets('dataset_list_screen empty', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const DatasetListScreen(projectId: 'p1')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.datasetsEmptyHeadline), findsOneWidget);
  });

  testWidgets('dataset_browser empty and failure', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const DatasetBrowserScreen(
          datasetId: 'missing',
          failure: StorageFailure(message: 'gone', recoveryAction: 'retry'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('gone'), findsWidgets);

    await tester.pumpWidget(
      wrap(const DatasetBrowserScreen(datasetId: 'missing')),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.datasetsBrowserEmptyHeadline), findsOneWidget);
  });

  testWidgets('dataset_browser scroll and search over many rows', (
    WidgetTester tester,
  ) async {
    final ReferenceDataset dataset = switch (await repo.save(
      ReferenceDataset(
        id: 'ds',
        name: 'Big',
        keyColumn: 'code',
        columns: const <String>['code', 'name'],
        source: DatasetSource.device,
        importedAt: DateTime.utc(2026, 9, 22),
        rowCount: 0,
        projectId: 'p1',
      ),
    )) {
      Success<ReferenceDataset>(:final ReferenceDataset value) => value,
      FailureResult<ReferenceDataset>(:final Failure failure) =>
        throw TestFailure(failure.message),
    };
    for (int i = 0; i < 200; i++) {
      await repo.saveRow(
        ReferenceRow(
          id: 'r$i',
          datasetId: dataset.id,
          key: 'K$i',
          values: <String, String>{'code': 'K$i', 'name': 'N$i'},
        ),
      );
    }
    final Stopwatch watch = Stopwatch()..start();
    await tester.pumpWidget(
      wrap(DatasetBrowserScreen(datasetId: dataset.id, projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(4000));
  });

  testWidgets('row edit and add sheet empty/failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const DatasetRowEditScreen(
          rowId: 'missing',
          failure: StorageFailure(
            message: 'edit-fail',
            recoveryAction: 'retry',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('edit-fail'), findsWidgets);

    await tester.pumpWidget(
      wrap(
        const DatasetAddRowSheet(
          datasetId: '',
          keyColumn: 'code',
          binding: LookupBinding(
            datasetId: 'ds',
            matchColumns: <String>['code'],
            fillMapping: <String, String>{'name': 'supplier'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.datasetsEmptyHeadline), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        const DatasetAddRowSheet(
          datasetId: 'ds',
          keyColumn: 'code',
          binding: LookupBinding(
            datasetId: 'ds',
            matchColumns: <String>['code'],
            fillMapping: <String, String>{'name': 'supplier'},
          ),
          failure: StorageFailure(message: 'add-fail', recoveryAction: 'retry'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('add-fail'), findsWidgets);
  });

  testWidgets('lookup picker empty and failure', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const LookupPickerSheet(
          matches: <ReferenceRow>[],
          distinguishColumns: <String>['name'],
        ),
      ),
    );
    expect(find.text(Copy.datasetsBrowserEmptyHeadline), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        const LookupPickerSheet(
          matches: <ReferenceRow>[],
          distinguishColumns: <String>['name'],
          failure: StorageFailure(
            message: 'pick-fail',
            recoveryAction: 'retry',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('pick-fail'), findsWidgets);
  });
}
