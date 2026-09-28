import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/account/presentation/backend_settings_screen.dart';
import '../../../support/pump_app.dart';

void main() {
  for (final double width in <double>[360, 768, 1280]) {
    testWidgets('cached account details fit width $width at 200 percent text', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpApp(
        tester,
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: const TextScaler.linear(2),
          ),
          child: BackendSettingsScreen(
            config: BackendConfig(
              baseUrl: 'https://organisation.example.test',
              accountEmail: 'person@example.test',
              state: EnrolmentState.enrolled,
              grantValidUntil: DateTime.utc(2026, 10, 28),
              reachable: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(Copy.backendSignedIn), findsOneWidget);
      expect(find.text(Copy.backendUnreachable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
