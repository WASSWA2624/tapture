import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/account/presentation/relay_settings_screen.dart';

void main() {
  testWidgets('relay stays off until a manager enables it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const RelaySettingsScreen(
          enabled: false,
          neverRelay: false,
          queued: 2,
          sent: 1,
          purged: 0,
        ),
      ),
    );
    expect(find.text(Copy.relayOff), findsOneWidget);
    expect(find.text(Copy.relaySend), findsNothing);
    expect(find.text('${Copy.relayQueued} 2'), findsOneWidget);
    expect(find.text('${Copy.relaySent} 1'), findsOneWidget);
    expect(find.text('${Copy.relayPurged} 0'), findsOneWidget);
  });

  testWidgets('a never-relay project offers no send', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const RelaySettingsScreen(
          enabled: true,
          neverRelay: true,
          queued: 0,
          sent: 0,
          purged: 3,
        ),
      ),
    );
    expect(find.text(Copy.relayNever), findsOneWidget);
    expect(find.text(Copy.relaySend), findsNothing);
  });

  testWidgets('an enabled relay can send', (WidgetTester tester) async {
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: RelaySettingsScreen(
          enabled: true,
          neverRelay: false,
          queued: 1,
          sent: 0,
          purged: 0,
          onSend: () => sent += 1,
        ),
      ),
    );
    await tester.tap(find.text(Copy.relaySend));
    expect(sent, 1);
  });
}
