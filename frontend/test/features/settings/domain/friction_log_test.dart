import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/settings/domain/friction_log.dart';
import 'package:tapture/features/settings/presentation/friction_log_button.dart';

import '../../../support/pump_app.dart';

void main() {
  test(
    'an entry keeps the screen, project and last action, and export lists them',
    () async {
      final FrictionLog log = FrictionLog();
      await log.logFriction(
        screen: 'capture',
        action: 'save',
        at: DateTime.utc(2026, 9, 28),
        projectId: 'project-1',
        note: 'shutter stuck',
        screenshotPath: 'shots/1.png',
      );
      final String exported = log.exportText();
      expect(exported, contains('capture'));
      expect(exported, contains('project-1'));
      expect(exported, contains('save'));
      expect(exported, contains('shots/1.png'));
    },
  );

  testWidgets('the action is absent when the trial flag is off', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      FrictionLogButton(
        trial: false,
        log: FrictionLog(),
        screen: 'capture',
        action: 'save',
        at: DateTime.utc(2026, 9, 28),
      ),
    );
    expect(find.text(Copy.frictionLogAction), findsNothing);
  });
}
