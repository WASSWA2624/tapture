import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/exports/exports.dart';
import 'package:tapture/features/exports/presentation/export_workflow_screen.dart';
import 'package:tapture/features/projects/presentation/project_export_screen.dart';

import '../support/empty_state_matchers.dart';
import '../support/fakes/fake_export_repository.dart';
import '../support/pump_external_work.dart';
import '../support/screen_fixture.dart';
import '../support/screen_fixtures.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('the project row starts one export and Back keeps its package', (
    WidgetTester tester,
  ) async {
    final ScreenHarness harness = await ScreenHarness.pump(
      tester,
      const ScreenFixture(
        'ProjectListScreen',
        RoutePaths.projects,
        record: true,
      ),
    );
    final FakeExportRepository exports =
        harness.container.read(exportRepositoryProvider)!
            as FakeExportRepository;
    expect(exports.exportCalls, 0);
    await tester.tap(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('project-row-${ScreenFixtures.project}'),
        ),
        matching: find.byType(AppOverflowMenu),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectExport));
    await harness.expectLocation(
      tester,
      RoutePaths.projectExports(ScreenFixtures.project),
    );
    await tester.pumpAndSettle();
    expect(exports.exportCalls, 1);
    expect(
      tester
          .widget<ProjectExportScreen>(find.byType(ProjectExportScreen))
          .startExport,
      isTrue,
    );
    expect(find.text(Copy.projectExport), findsNothing);

    unawaited(
      harness.router.push<void>(
        RoutePaths.projectDeliverables(ScreenFixtures.project),
      ),
    );
    await tester.pumpAndSettle();
    harness.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ProjectExportScreen), findsOneWidget);
    expect(exports.exportCalls, 1);
    expect(find.text(Copy.projectExportShare), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty project package opens capture for its owner', (
    WidgetTester tester,
  ) async {
    final ScreenHarness harness = await ScreenHarness.pump(
      tester,
      ScreenFixture(
        'ProjectExportScreen',
        RoutePaths.projectExports(ScreenFixtures.project),
      ),
    );
    await expectEmptyState(tester, action: Copy.recordsEmptyAction);
    await tester.tap(find.widgetWithText(AppButton, Copy.recordsEmptyAction));
    await harness.expectLocation(
      tester,
      RoutePaths.projectCapture(ScreenFixtures.project),
    );
  });

  testWidgets('the canonical deliverable route opens capture with no records', (
    WidgetTester tester,
  ) async {
    final ScreenHarness harness = await ScreenHarness.pump(
      tester,
      ScreenFixture(
        'ExportWorkflowScreen',
        RoutePaths.projectDeliverables(ScreenFixtures.project),
      ),
    );
    final Finder workflow = find.byType(ExportWorkflowScreen);
    await expectEmptyState(
      tester,
      action: Copy.recordsEmptyAction,
      within: workflow,
    );
    await tester.tap(
      find.descendant(
        of: workflow,
        matching: find.widgetWithText(AppButton, Copy.recordsEmptyAction),
      ),
    );
    await harness.expectLocation(
      tester,
      RoutePaths.projectCapture(ScreenFixtures.project),
    );
  });

  testWidgets('the legacy deliverable URL preserves its query and fragment', (
    WidgetTester tester,
  ) async {
    final Uri canonical = Uri(
      path: RoutePaths.projectDeliverables(ScreenFixtures.project),
      queryParameters: const <String, String>{'scope': 'approved'},
      fragment: 'history',
    );
    final ScreenHarness harness = await ScreenHarness.pump(
      tester,
      ScreenFixture(
        'ExportWorkflowScreen',
        Uri(
          path: '${RoutePaths.project(ScreenFixtures.project)}/deliverable',
          query: canonical.query,
          fragment: canonical.fragment,
        ).toString(),
      ),
      expectedLocation: canonical.toString(),
    );
    expect(harness.router.routeInformationProvider.value.uri, canonical);
    expect(find.byType(ExportWorkflowScreen), findsOneWidget);
  });

  testWidgets('Output files opens the real selected project workflow', (
    WidgetTester tester,
  ) async {
    final ScreenHarness harness = await ScreenHarness.pump(
      tester,
      ScreenFixture(
        'ProjectExportScreen',
        RoutePaths.projectExports(ScreenFixtures.project),
        record: true,
      ),
    );
    final Finder output = find.byKey(
      const ValueKey<String>('project-export-deliverables'),
    );
    await tester.tap(find.byKey(const ValueKey<String>('app-page-overflow')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(output);
    await tester.tap(output);
    await harness.expectLocation(
      tester,
      RoutePaths.projectDeliverables(ScreenFixtures.project),
    );
    await pumpExternalWork(tester, () {
      final Finder workflow = find.byType(ExportWorkflowScreen);
      return workflow.evaluate().length == 1 &&
          find
              .descendant(of: workflow, matching: find.byType(AppSkeleton))
              .evaluate()
              .isEmpty;
    });
    final ExportWorkflowScreen workflow = tester.widget(
      find.byType(ExportWorkflowScreen),
    );
    expect(workflow.projectId, ScreenFixtures.project);
    expect(tester.takeException(), isNull);
  });
}
