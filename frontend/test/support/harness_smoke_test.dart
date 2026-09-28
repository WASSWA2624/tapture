import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/harness.dart';
import 'fakes.dart';
import 'pump_app.dart';

void main() {
  testWidgets('pumpApp installs the theme for light, dark and outdoor', (
    WidgetTester tester,
  ) async {
    for (final ({Brightness brightness, bool outdoor}) mode
        in <({Brightness brightness, bool outdoor})>[
          (brightness: Brightness.light, outdoor: false),
          (brightness: Brightness.dark, outdoor: false),
          (brightness: Brightness.light, outdoor: true),
        ]) {
      await pumpApp(
        tester,
        const Text('Ready'),
        brightness: mode.brightness,
        outdoor: mode.outdoor,
        now: DateTime.utc(2026, 9, 28),
      );
      await pumpUntil(tester, () => find.text('Ready').evaluate().isNotEmpty);
      expect(find.text('Ready'), findsOneWidget);
    }
  });

  test('bootTestApp refuses a real socket', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    expect(app.outboundCallCount, 0);
    expect(app.backend.signIn(), isTrue);
    expect(
      () => app.socket.block('ai.example'),
      throwsA(isA<HarnessSocketError>()),
    );
    expect(app.outboundCallCount, 1);
  });
}
