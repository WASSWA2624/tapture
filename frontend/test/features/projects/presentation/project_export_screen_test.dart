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
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/exports/exports.dart';
import 'package:tapture/features/projects/presentation/project_export_screen.dart';

import '../../../support/fakes/fake_export_repository.dart';

void main() {
  testWidgets('an empty project explains that there is nothing to export', (
    WidgetTester tester,
  ) async {
    final FakeExportRepository exports = FakeExportRepository();
    addTearDown(exports.dispose);
    await _pump(tester, exports: exports);
    expect(find.text(Copy.projectExportEmptyHeadline), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
  });

  testWidgets('with no export store the page says the files are not here', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(
      find.text('Project files are not available on this device.'),
      findsOneWidget,
    );
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '393 dp', size: const Size(393, 886), scale: 1),
        (name: '800 dp', size: const Size(800, 1000), scale: 1),
        (name: '1200 dp', size: const Size(1200, 800), scale: 1),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
      ]) {
    testWidgets('at ${layout.name} the summary lists what the file holds', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = layout.size;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final FakeExportRepository exports = FakeExportRepository()
        ..summary = _summary;
      addTearDown(exports.dispose);
      await _pump(
        tester,
        exports: exports,
        downloads: DownloadService.fake(destination: 'Downloads › Tapture'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Testing'), findsOneWidget);
      expect(find.text(Copy.recordsCount(3)), findsOneWidget);
      expect(find.text(Copy.capturePhotoCount(3)), findsNothing);
      expect(find.text(Copy.capturePhotoCount(5)), findsOneWidget);
      expect(find.text(Copy.exportAudioClips(1)), findsOneWidget);
      expect(find.text(Copy.exportUnprocessedCount(1)), findsOneWidget);
      expect(find.text(Copy.exportNeedsReviewCount(1)), findsOneWidget);
      expect(find.text(Copy.exportApprovedCount(1)), findsOneWidget);
      expect(find.text('Assets'), findsOneWidget);
      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text(Copy.exportFileFormat), findsOneWidget);
      expect(find.text(Copy.exportFileColumns), findsOneWidget);
      expect(
        find.text(Copy.exportSavedTo('Downloads › Tapture')),
        findsOneWidget,
      );
      final Rect action = tester.getRect(find.byType(AppPrimaryAction));
      expect(action.bottom, lessThanOrEqualTo(layout.size.height));
      expect(
        tester.widget<AppPrimaryAction>(find.byType(AppPrimaryAction)).label,
        Copy.projectExport,
      );
    });
  }

  testWidgets('offline shows a banner and share runs only from Share', (
    WidgetTester tester,
  ) async {
    final FakeExportRepository exports = FakeExportRepository(
      displayName: 'Testing-250926-190542.xlsx',
    )..summary = _summary;
    addTearDown(exports.dispose);
    var shared = 0;
    await _pump(
      tester,
      exports: exports,
      overrides: <Override>[offlineNowProvider.overrideWith((Ref _) => true)],
      downloads: DownloadService.fake(
        canOpenExternally: true,
        onOpenExternally: (String _, Uint8List _, String _) => shared++,
      ),
    );
    expect(find.text(Copy.offlineWorking), findsOneWidget);

    await tester.tap(find.text(Copy.projectExport));
    await tester.pumpAndSettle();
    expect(
      find.text(Copy.projectExportSaved('Testing-250926-190542.xlsx')),
      findsOneWidget,
    );
    expect(find.text('Testing'), findsOneWidget);
    expect(shared, 0);

    await tester.tap(find.text(Copy.projectExportShare));
    await tester.pumpAndSettle();
    expect(shared, 1);
  });

  testWidgets('cancel leaves the export unwritten', (
    WidgetTester tester,
  ) async {
    await _pump(tester, exports: _HoldExport());
    await tester.tap(find.text(Copy.projectExport));
    await tester.pump();
    expect(find.text(Copy.projectExportProgress), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, Copy.projectExportCancel));
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectExportShare), findsNothing);
    expect(
      tester.widget<AppPrimaryAction>(find.byType(AppPrimaryAction)).onPressed,
      isNotNull,
    );
  });

  testWidgets('a saved export keeps its name when the copy fails', (
    WidgetTester tester,
  ) async {
    final FakeExportRepository exports = FakeExportRepository(
      displayName: 'Test-project-240926-110000.xlsx',
    )..summary = _summary;
    addTearDown(exports.dispose);
    await _pump(
      tester,
      exports: exports,
      downloads: DownloadService.fake(fail: true),
    );
    await tester.tap(find.text(Copy.projectExport));
    await tester.pumpAndSettle();
    expect(
      find.text(Copy.projectExportSaved('Test-project-240926-110000.xlsx')),
      findsOneWidget,
    );
    expect(find.textContaining('could not save'), findsOneWidget);
  });

  testWidgets('a failed share says why, and a dismissed one says nothing', (
    WidgetTester tester,
  ) async {
    for (final ({DownloadService downloads, bool snack}) run
        in <({DownloadService downloads, bool snack})>[
          (
            downloads: DownloadService.fake(
              canOpenExternally: true,
              openPermissionDenied: true,
            ),
            snack: true,
          ),
          (
            downloads: DownloadService.fake(
              canOpenExternally: true,
              openCancel: true,
            ),
            snack: false,
          ),
          (
            downloads: DownloadService.fake(canOpenExternally: true),
            snack: false,
          ),
        ]) {
      final FakeExportRepository exports = FakeExportRepository()
        ..summary = _summary;
      addTearDown(exports.dispose);
      await _pump(tester, exports: exports, downloads: run.downloads);
      await tester.tap(find.text(Copy.projectExport));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.projectExportShare));
      await tester.pumpAndSettle();
      expect(
        find.text(Copy.projectOpenPermission),
        run.snack ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('the share hint shows only where the sheet reaches other apps', (
    WidgetTester tester,
  ) async {
    for (final bool sheet in <bool>[true, false]) {
      final FakeExportRepository exports = FakeExportRepository()
        ..summary = _summary;
      addTearDown(exports.dispose);
      await _pump(
        tester,
        exports: exports,
        downloads: DownloadService.fake(
          canOpenExternally: true,
          canShareToApps: sheet,
        ),
      );
      await tester.tap(find.text(Copy.projectExport));
      await tester.pumpAndSettle();
      expect(
        find.text(Copy.projectExportShareHint),
        sheet ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

final ExportSummary _summary = (
  projectName: 'Testing',
  records: 3,
  photos: 5,
  audioClips: 1,
  unprocessed: 1,
  needsReview: 1,
  approved: 1,
  templates: const <ExportTemplateCount>[
    (name: 'Assets', records: 2),
    (name: 'Rooms', records: 1),
  ],
  firstCapturedAt: DateTime.utc(2026, 9, 24, 9),
  lastCapturedAt: DateTime.utc(2026, 9, 25, 16),
);

Future<void> _pump(
  WidgetTester tester, {
  ExportRepository? exports,
  DownloadService? downloads,
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[
        if (exports != null)
          exportRepositoryProvider.overrideWith((Ref _) => exports),
        if (downloads != null)
          downloadServiceProvider.overrideWith((Ref _) => downloads),
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

  @override
  Stream<ExportSummary> watchSummary(String projectId) =>
      Stream<ExportSummary>.value(_summary);
}
