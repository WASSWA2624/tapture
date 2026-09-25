import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/exports/exports.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/presentation/project_export_screen.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/fakes/fake_export_repository.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('an empty project explains that there is nothing to export', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    await _pump(tester, projects: projects);
    expect(find.text(Copy.projectExportEmptyHeadline), findsOneWidget);
  });

  testWidgets('offline copy is shown and share runs only from Share', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    projects.seedRecords('project-1', const <ProjectRecordRow>[
      (
        id: 'r1',
        templateId: 't1',
        status: 'captured',
        photoCount: 1,
        thumbPath: null,
        fields: <ProjectRecordFieldValue>[],
      ),
    ]);
    final FakeExportRepository exports = FakeExportRepository();
    addTearDown(exports.dispose);
    var shared = 0;
    await _pump(
      tester,
      projects: projects,
      overrides: <Override>[
        exportRepositoryProvider.overrideWith((Ref _) => exports),
        projectExportOfflineProvider.overrideWith((Ref _) => true),
        downloadServiceProvider.overrideWith(
          (Ref _) => DownloadService.fake(
            canOpenExternally: true,
            onOpenExternally: (String _, Uint8List _, String _) => shared++,
          ),
        ),
      ],
    );
    expect(find.text(Copy.offlineWorking), findsOneWidget);
    expect(shared, 0);
    await tester.tap(find.widgetWithText(AppButton, Copy.projectExport));
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectExportWrote), findsOneWidget);
    expect(shared, 0);
    await tester.tap(find.text(Copy.projectExportShare));
    await tester.pumpAndSettle();
    expect(shared, 1);
  });

  testWidgets('missing project files show the storage failure', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    projects.seedRecords('project-1', const <ProjectRecordRow>[
      (
        id: 'r1',
        templateId: 't1',
        status: 'captured',
        photoCount: 1,
        thumbPath: null,
        fields: <ProjectRecordFieldValue>[],
      ),
    ]);
    await _pump(tester, projects: projects);
    await tester.tap(find.widgetWithText(AppButton, Copy.projectExport));
    await tester.pump();
    expect(
      find.text('Project files are not available on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('cancel leaves the export unshared', (WidgetTester tester) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    projects.seedRecords('project-1', const <ProjectRecordRow>[
      (
        id: 'r1',
        templateId: 't1',
        status: 'captured',
        photoCount: 1,
        thumbPath: null,
        fields: <ProjectRecordFieldValue>[],
      ),
    ]);
    await _pump(
      tester,
      projects: projects,
      overrides: <Override>[
        exportRepositoryProvider.overrideWith((Ref _) => _HoldExport()),
      ],
    );
    await tester.tap(find.widgetWithText(AppButton, Copy.projectExport));
    await tester.pump();
    expect(find.text(Copy.projectExportProgress), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, Copy.projectExportCancel));
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectExportWrote), findsNothing);
    expect(find.widgetWithText(AppButton, Copy.projectExport), findsOneWidget);
  });

  testWidgets(
    'a saved export shows the display name and keeps it when the copy fails',
    (WidgetTester tester) async {
      final FakeProjectRepository projects = FakeProjectRepository();
      addTearDown(projects.dispose);
      projects.seedRecords('project-1', const <ProjectRecordRow>[
        (
          id: 'r1',
          templateId: 't1',
          status: 'captured',
          photoCount: 1,
          thumbPath: null,
          fields: <ProjectRecordFieldValue>[],
        ),
      ]);
      final FakeExportRepository exports = FakeExportRepository(
        displayName: 'Test-project-240926-110000.xlsx',
      );
      addTearDown(exports.dispose);
      await _pump(
        tester,
        projects: projects,
        overrides: <Override>[
          exportRepositoryProvider.overrideWith((Ref _) => exports),
          downloadServiceProvider.overrideWith(
            (Ref _) => DownloadService.fake(fail: true),
          ),
        ],
      );
      await tester.tap(find.widgetWithText(AppButton, Copy.projectExport));
      await tester.pumpAndSettle();
      expect(find.text(Copy.projectExportWrote), findsOneWidget);
      expect(find.text('Test-project-240926-110000.xlsx'), findsOneWidget);
      expect(find.textContaining('could not save'), findsOneWidget);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeProjectRepository projects,
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const ProjectExportScreen(projectId: 'project-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _HoldExport implements ExportRepository {
  CancellationToken? token;

  @override
  Future<Result<ExportEntry?>> byId(String id) async =>
      const Success<ExportEntry?>(null);

  @override
  Future<Result<void>> delete(String id, {required String reason}) async =>
      const Success<void>(null);

  @override
  Future<Result<ExportedWorkbook>> exportProject(
    String projectId, {
    required CancellationToken cancel,
  }) {
    token = cancel;
    return cancel.whenCancelled.then(
      (_) => const FailureResult<ExportedWorkbook>(CancelledFailure()),
    );
  }

  @override
  Future<Result<ExportEntry>> save(ExportEntry entry) async =>
      const FailureResult<ExportEntry>(ValidationFailure());

  @override
  Stream<List<ExportEntry>> watchByProject(String projectId) =>
      const Stream<List<ExportEntry>>.empty();
}
