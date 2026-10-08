import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/route_paths.dart';

import '../../../support/screen_fixture.dart';
import '../../../support/screen_harness.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

void main() {
  for (final ScreenFixture fixture in <ScreenFixture>[
    ScreenFixture('ProjectHomeScreen', RoutePaths.project('created-1')),
    const ScreenFixture(
      'ProjectCreateScreen',
      RoutePaths.projectCreate,
      project: false,
    ),
    ScreenFixture('ProjectEditScreen', RoutePaths.projectEdit('created-1')),
    const ScreenFixture(
      'ProjectListScreen',
      RoutePaths.projects,
      project: false,
    ),
    const ScreenFixture(
      'ImportScreen',
      RoutePaths.projectImport,
      project: false,
    ),
  ]) {
    for (final ({String name, ScreenMatrix cell}) corner
        in ScreenMatrix.corners) {
      testWidgets('${fixture.screen} feedback golden ${corner.name}', (
        WidgetTester tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = corner.cell.size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final ScreenHarness harness = await ScreenHarness.pump(
          tester,
          fixture,
          brightness: corner.cell.brightness,
          outdoor: corner.cell.outdoor,
          textScale: corner.cell.textScale,
        );
        try {
          expect(ScreenProbe.layoutIssues(tester), isEmpty);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/field_workflow_${fixture.screen}_${corner.name}.png',
            ),
          );
        } finally {
          await harness.close(tester);
        }
      });
    }
  }
}
