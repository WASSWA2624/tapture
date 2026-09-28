import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_api_client.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/grant_cache.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/account/presentation/backend_settings_screen.dart';
import 'package:tapture/features/account/presentation/sign_in_screen.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('sign-in submits the address and password once', (
    WidgetTester tester,
  ) async {
    String? email;
    String? password;
    await pumpApp(
      tester,
      SignInScreen(
        onSubmit: (String nextEmail, String nextPassword) async {
          email = nextEmail;
          password = nextPassword;
        },
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'a@acme.test');
    await tester.enterText(find.byType(TextField).at(1), 'correct-horse');
    await tester.tap(find.widgetWithText(AppButton, Copy.signInAction));
    await tester.pump();
    expect(email, 'a@acme.test');
    expect(password, 'correct-horse');
  });

  test(
    'silent refresh stays local when the server cannot be reached',
    () async {
      var calls = 0;
      final BackendApiClient client = BackendApiClient(
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async {
              calls += 1;
              return (
                status: 200,
                body: <String, Object?>{
                  'accessToken': 'next-access',
                  'refreshToken': 'next-refresh',
                },
              );
            },
      );
      final TokenPair offline = await client.refresh(
        refreshToken: 'cached-refresh',
        reachable: false,
        cachedAccess: 'cached-access',
      );
      expect(calls, 0);
      expect(offline.accessToken, 'cached-access');
      final TokenPair online = await client.refresh(
        refreshToken: 'cached-refresh',
        reachable: true,
      );
      expect(calls, 1);
      expect(online.accessToken, 'next-access');
    },
  );

  test('a session is written only to secure storage', () {
    final Map<String, String> secrets = <String, String>{};
    final Map<String, String> database = <String, String>{};
    final List<String> logs = <String>[];
    final List<String> exports = <String>[];
    final GrantCache cache = GrantCache(
      secrets: secrets,
      database: database,
      logs: logs,
      exports: exports,
      now: () => DateTime.utc(2026, 1, 1),
    );
    cache.save(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      organisationId: 'org-1',
      refreshedAt: DateTime.utc(2026, 1, 1),
    );
    expect(database, isEmpty);
    expect(logs, isEmpty);
    expect(exports, isEmpty);
    expect(secrets.values.single.contains('org-1'), isTrue);
    expect(secrets.values.single.contains('access-token'), isTrue);
  });

  testWidgets('an unreachable server is one quiet line', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const BackendSettingsScreen(
        config: BackendConfig(
          baseUrl: 'https://org.example',
          accountEmail: 'a@acme.test',
          state: EnrolmentState.enrolled,
          reachable: false,
        ),
      ),
    );
    expect(find.text(Copy.backendUnreachable), findsOneWidget);
    expect(find.byType(AppErrorState), findsNothing);
  });
}
