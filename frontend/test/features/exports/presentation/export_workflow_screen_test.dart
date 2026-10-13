import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/features/exports/exports.dart';
import 'package:tapture/features/exports/presentation/export_workflow_screen.dart';

import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

void main() {
  testWidgets(
    'compact export retains defaults and opens advanced options together',
    (WidgetTester tester) async {
      await _pump(tester, _Store());
      expect(
        tester.widget<AppPage>(find.byType(AppPage)).layout,
        AppPageLayout.compact,
      );
      expect(find.byType(AppSection), findsNWidgets(5));
      expect(find.text(Copy.exportDictionary), findsNothing);
      final Finder advanced = find.byKey(
        const ValueKey<String>('export-advanced'),
      );
      expect(tester.widget<AppSectionHeader>(advanced).expanded, isFalse);
      await tester.ensureVisible(advanced);
      await tester.tap(advanced);
      await tester.pumpAndSettle();
      expect(tester.widget<AppSectionHeader>(advanced).expanded, isTrue);
      expect(find.text(Copy.exportConfidence), findsOneWidget);
      expect(find.text(Copy.exportDictionary), findsOneWidget);
      expect(find.text(Copy.exportPhotoMode), findsOneWidget);
      await tester.ensureVisible(advanced);
      await tester.tap(advanced);
      await tester.pumpAndSettle();
      expect(find.text(Copy.exportDictionary), findsNothing);
    },
  );

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'export controls remain reachable with advanced options ${cell.description}',
      (WidgetTester tester) async {
        final _Store store = _Store()..holdWrite = true;
        await _pump(tester, store, cell: cell);
        expect(store.written, isEmpty);
        final Finder run = find.byKey(const ValueKey<String>('export-run'));
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            reachableTargets: <Finder>[run],
          ),
          isEmpty,
        );
        final Finder advanced = find.byKey(
          const ValueKey<String>('export-advanced'),
        );
        await tester.ensureVisible(advanced);
        await tester.tap(advanced);
        await tester.pumpAndSettle();
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
        await tester.ensureVisible(find.text(Copy.exportDelimiter));
        await tester.pumpAndSettle();
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
        expect(store.written, isEmpty);
        await tester.tap(run);
        final Finder cancel = find.byKey(
          const ValueKey<String>('export-cancel'),
        );
        await _until(tester, cancel);
        expect(
          tester.widget<AppPage>(find.byType(AppPage)).layout,
          AppPageLayout.compact,
        );
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            reachableTargets: <Finder>[cancel],
          ),
          isEmpty,
        );
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(store.cancelled, isTrue);
      },
    );
  }

  testWidgets('the production route writes a clean default in one tap', (
    WidgetTester tester,
  ) async {
    final _Store store = _Store();
    await _pump(tester, store);
    expect(find.text(Copy.exportCount(1)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('export-run')));
    await tester.pumpAndSettle();
    expect(store.written, hasLength(1));
    expect(store.written.single.records.single.id, 'r1');
    expect(find.text(Copy.exportShare), findsWidgets);
  });

  testWidgets('the export gate excludes invalid rows before writing', (
    WidgetTester tester,
  ) async {
    final _Store store = _Store()..invalid = true;
    await _pump(tester, store);
    await tester.tap(find.byKey(const ValueKey<String>('export-run')));
    await _until(tester, find.text(Copy.exportExclude));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.written, isEmpty);
    await tester.tap(find.text(Copy.exportExclude));
    await tester.pumpAndSettle();
    expect(store.written.single.records, isEmpty);
  });

  testWidgets('dismissing the export gate leaves every writer untouched', (
    WidgetTester tester,
  ) async {
    final _Store store = _Store()..invalid = true;
    await _pump(tester, store);
    await tester.tap(find.byKey(const ValueKey<String>('export-run')));
    await _until(tester, find.text(Copy.exportExclude));
    await tester.pump(const Duration(milliseconds: 300));
    Navigator.of(tester.element(find.text(Copy.exportExclude))).pop();
    await tester.pumpAndSettle();
    expect(store.written, isEmpty);
    expect(find.byKey(const ValueKey<String>('export-run')), findsOneWidget);
  });

  testWidgets('cancel signals the active writer and permits another run', (
    WidgetTester tester,
  ) async {
    final _Store store = _Store()..holdWrite = true;
    await _pump(tester, store);
    await tester.tap(find.byKey(const ValueKey<String>('export-run')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('export-cancel')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('export-cancel')));
    await tester.pumpAndSettle();
    expect(store.cancelled, isTrue);
    expect(find.byKey(const ValueKey<String>('export-run')), findsOneWidget);
  });

  testWidgets('failed options show a recoverable error on the route', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _Store()..failOptions = true);
    expect(find.text('Options could not be read.'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('export-run')), findsNothing);
  });
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (int frame = 0; frame < 60; frame++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('The expected export control did not appear.');
}

Future<void> _pump(
  WidgetTester tester,
  _Store store, {
  ScreenMatrix? cell,
}) async {
  if (cell != null) {
    tester.view.physicalSize = cell.size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [deliverableRepositoryProvider.overrideWithValue(store)],
      child: MaterialApp(
        theme: buildTheme(
          brightness: cell?.brightness ?? Brightness.light,
          outdoor: cell?.outdoor ?? false,
        ),
        builder: (BuildContext context, Widget? child) => cell == null
            ? child!
            : MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(cell.textScale)),
                child: child!,
              ),
        home: const ExportWorkflowScreen(projectId: 'p1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _Store implements DeliverableRepository {
  bool invalid = false;
  bool holdWrite = false;
  bool failOptions = false;
  bool cancelled = false;
  final List<ExportRequest> written = <ExportRequest>[];
  final List<DeliverableEntry> history = <DeliverableEntry>[];

  @override
  Future<Result<ExportRequest>> options(String projectId) async => failOptions
      ? const FailureResult<ExportRequest>(
          StorageFailure(message: 'Options could not be read.'),
        )
      : const Success<ExportRequest>(
          ExportRequest(
            projectId: 'p1',
            formats: <ExportFormat>{ExportFormat.xlsx},
            scope: (
              kind: ExportScopeKind.approved,
              context: null,
              from: null,
              to: null,
              filter: null,
            ),
            columns: (
              raw: false,
              refined: true,
              confidence: false,
              evidence: false,
            ),
            extras: (
              dictionary: false,
              photoIndex: true,
              photoMode: 'relative',
              pdfPhotos: 'thumbnail',
              delimiter: ',',
            ),
          ),
        );

  @override
  Future<Result<void>> remember(ExportRequest request) async =>
      const Success<void>(null);

  @override
  Stream<int> watchCount(ExportRequest request) => Stream<int>.value(1);

  @override
  Future<Result<PreparedDeliverable>> prepare(
    ExportRequest request, {
    required CancellationToken cancel,
  }) async => Success<PreparedDeliverable>((
    request: request.copyWith(
      records: const <ExportRecord>[
        ExportRecord(
          id: 'r1',
          number: '1',
          templateId: 't1',
          templateName: 'Asset',
          status: 'approved',
          approved: true,
        ),
      ],
    ),
    validation: (
      incomplete: invalid ? <String>['r1'] : <String>[],
      unapproved: <String>[],
      blocked: <String>[],
    ),
  ));

  @override
  Future<Result<DeliverableEntry>> write(
    ExportRequest request, {
    required CancellationToken cancel,
    void Function(DeliverableProgress)? onProgress,
  }) async {
    onProgress?.call((stage: 'reports', fraction: 0));
    if (holdWrite) {
      await cancel.whenCancelled;
      cancelled = true;
      return const FailureResult<DeliverableEntry>(CancelledFailure());
    }
    written.add(request);
    final DeliverableEntry entry = (
      id: 'e1',
      projectId: 'p1',
      projectName: 'Plant',
      version: 1,
      createdAt: DateTime.utc(2026, 9, 30),
      operatorName: 'Ada',
      recordCount: request.records.length,
      path: 'projects/plant/exports/records.xlsx',
      fileName: 'Plant_v1.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      sha256: 'abc',
      missing: false,
      package: false,
    );
    history.add(entry);
    return Success<DeliverableEntry>(entry);
  }

  @override
  Stream<List<DeliverableEntry>> watchHistory({String? projectId}) =>
      Stream<List<DeliverableEntry>>.value(history);

  @override
  Future<Result<ExportRequest>> replay(String exportId) async =>
      Success<ExportRequest>(written.first);
}
