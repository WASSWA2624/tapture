import 'package:flutter_test/flutter_test.dart';

import '../support/empty_state_matchers.dart';
import '../support/screen_fixture.dart';
import '../support/screen_fixtures.dart';
import '../support/screen_harness.dart';
import '../support/screen_matrix.dart';
import '../support/screen_probe.dart';

void main() {
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
          await ScreenProbe.accessibilityIssues(tester),
          isEmpty,
          reason: '${fixture.screen} ${cell.description}',
        );
      });
    }
  }
}
