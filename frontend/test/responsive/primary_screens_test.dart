import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/features/projects/presentation/export_summary_view.dart';

import '../support/empty_state_matchers.dart';
import '../support/screen_fixture.dart';
import '../support/screen_fixtures.dart';
import '../support/screen_harness.dart';
import '../support/screen_matrix.dart';
import '../support/screen_probe.dart';

void main() {
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets('populated export details are optional ${cell.description}', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = cell.size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await ScreenHarness.pump(
        tester,
        ScreenFixture(
          'ProjectExportScreen',
          RoutePaths.projectExports(ScreenFixtures.project),
          record: true,
        ),
        brightness: cell.brightness,
        outdoor: cell.outdoor,
        textScale: cell.textScale,
      );
      expect(find.byType(ExportSummaryView), findsNothing);
      final Finder heading = find.byKey(
        const ValueKey<String>('project-export-summary'),
      );
      await tester.ensureVisible(heading);
      tester.widget<AppSectionHeader>(heading).onToggle!();
      await tester.pumpAndSettle();
      expect(find.byType(ExportSummaryView), findsOneWidget);
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
    });
  }
  for (final ScreenFixture fixture in ScreenFixtures.primary) {
    for (final ScreenMatrix cell in ScreenMatrix.cells) {
      testWidgets('${fixture.screen}: ${cell.description}', (
        WidgetTester tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = cell.size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await ScreenHarness.pump(
          tester,
          fixture,
          brightness: cell.brightness,
          outdoor: cell.outdoor,
          textScale: cell.textScale,
        );
        await expectEmptyState(
          tester,
          action: fixture.action!,
          within: find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == fixture.screen,
          ),
        );
        expect(
          ScreenProbe.layoutIssues(tester),
          isEmpty,
          reason: '${fixture.screen} ${cell.description}',
        );
      });
    }
  }
}
