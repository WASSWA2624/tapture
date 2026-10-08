import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';

import '../support/screen_fixture.dart';
import '../support/screen_fixtures.dart';
import '../support/screen_harness.dart';
import '../support/screen_matrix.dart';
import '../support/screen_probe.dart';

void main() {
  for (final ScreenFixture fixture in ScreenFixtures.primary) {
    for (final ScreenMatrix cell in ScreenMatrix.cells) {
      testWidgets('pseudo ${fixture.screen}: ${cell.description}', (
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
          locale: const Locale('en', 'XA'),
        );
        final Finder screen = find.byWidgetPredicate(
          (Widget w) => w.runtimeType.toString() == fixture.screen,
        );
        expect(
          AppLocalizations.of(tester.element(screen))!.localeName,
          'en_XA',
        );
        expect(
          ScreenProbe.layoutIssues(tester),
          isEmpty,
          reason: 'pseudo ${fixture.screen} ${cell.description}',
        );
      });
    }
  }
}
