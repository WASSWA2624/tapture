import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/account/presentation/account_route.dart';
import 'package:tapture/features/account/presentation/account_session.dart';
import 'package:tapture/features/account/presentation/backend_settings_screen.dart';
import 'package:tapture/features/account/presentation/server_address_form.dart';
import 'package:tapture/features/account/presentation/sign_in_route.dart';
import 'package:tapture/features/account/presentation/sign_in_screen.dart';

import '../../support/pump_app.dart';

final DateTime _now = DateTime.utc(2026, 9, 28);

void main() {
  for (final String path in <String>[
    RoutePaths.settingsAccount,
    RoutePaths.signIn,
  ]) {
    testWidgets(
      'unconfigured $path retains inline server setup without changing the session',
      (WidgetTester tester) async {
        final BackendSession session = await _session(
          signedIn: false,
          configured: false,
        );
        final BackendConfig before = session.config;
        await _pumpRoutes(tester, session: session, initial: path);
        expect(find.byType(ServerAddressForm), findsOneWidget);
        expect(session.config, same(before));
      },
    );
  }

  testWidgets(
    'an offline account deep link retains its cached session and grant',
    (WidgetTester tester) async {
      final BackendSession session = await _session(
        signedIn: true,
        offline: true,
      );
      final BackendConfig before = session.config;
      final AuthorityState authority = session.authority;
      await _pumpRoutes(
        tester,
        session: session,
        initial: RoutePaths.settingsAccount,
      );
      expect(find.text('person@example.test'), findsOneWidget);
      expect(session.config, same(before));
      expect(session.authority, authority);
    },
  );

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
    await tester.tap(find.widgetWithText(AppPrimaryAction, Copy.signInAction));
    await tester.pump();
    expect(email, 'a@acme.test');
    expect(password, 'correct-horse');
  });

  testWidgets('the first-run sign-in lets work start without signing in', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpRoutes(
      tester,
      session: await _session(signedIn: false),
      initial: RoutePaths.signIn,
    );

    await tester.tap(find.text(Copy.signInLater));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, RoutePaths.projects);
  });

  testWidgets(
    'a sign-in opened from settings offers no skip and returns there once '
    'signed in',
    (WidgetTester tester) async {
      final BackendSession session = await _session(signedIn: false);
      final GoRouter router = await _pumpRoutes(
        tester,
        session: session,
        initial: RoutePaths.settingsAccount,
      );
      expect(find.text(Copy.backendNotSignedIn), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, Copy.signInAction));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, RoutePaths.signIn);
      expect(find.text(Copy.signInLater), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), 'a@acme.test');
      await tester.enterText(find.byType(TextField).at(1), 'correct-horse');
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.signInAction),
      );
      await _settle(tester);

      expect(router.state.uri.path, RoutePaths.settingsAccount);
      expect(session.config.state, EnrolmentState.enrolled);
      expect(find.text('a@acme.test'), findsOneWidget);
      expect(find.text(Copy.backendEnrolled), findsOneWidget);
    },
  );

  testWidgets(
    'sign-out asks first, warning that signing back in needs the server',
    (WidgetTester tester) async {
      final BackendSession session = await _session(signedIn: true);
      await _pumpRoutes(
        tester,
        session: session,
        initial: RoutePaths.settingsAccount,
      );

      await tester.tap(find.text(Copy.signOutAction));
      await tester.pumpAndSettle();
      expect(find.text(Copy.signOutMessage), findsOneWidget);
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();
      expect(session.config.needsSignIn, isFalse);

      await tester.tap(find.text(Copy.signOutAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.signOutAction).last);
      await _settle(tester);

      expect(session.config.needsSignIn, isTrue);
      expect(find.text(Copy.backendNotSignedIn), findsOneWidget);
    },
  );

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

/// A session restored from secure storage; its server accepts any sign-in
/// and grants a field operator one project.
Future<BackendSession> _session({
  required bool signedIn,
  bool configured = true,
  bool offline = false,
}) async {
  final String until = _now.add(const Duration(days: 30)).toIso8601String();
  final BackendSession session = BackendSession(
    storage: SecureStorage.fake(
      backing: <SecretKey, String>{
        SecretKey.backendSession: jsonEncode(<String, Object?>{
          'baseUrl': configured ? 'https://organisation.test' : '',
          if (signedIn) ...<String, Object?>{
            'accessToken': 'access',
            'refreshToken': 'refresh',
            'accountId': 'account',
            'accountEmail': 'person@example.test',
            'role': 'field_operator',
            'grantValidUntil': until,
          },
        }),
      },
    ),
    clock: FixedClock(_now),
    deviceId: 'device',
    offline: () => offline,
    send:
        ({
          required String method,
          required String path,
          Map<String, Object?>? body,
          String? token,
        }) async {
          if (path.endsWith('/login')) {
            return (
              status: 200,
              body: <String, Object?>{
                'accessToken': 'access',
                'refreshToken': 'refresh',
              },
            );
          }
          if (path.endsWith('/logout')) {
            return (status: 204, body: <String, Object?>{});
          }
          return (
            status: 200,
            body: <String, Object?>{
              'userId': 'account',
              'organisationId': 'organisation',
              'role': 'field_operator',
              'grants': <Object?>[],
              'grantValidUntil': until,
            },
          );
        },
  );
  await session.restore();
  addTearDown(session.dispose);
  return session;
}

/// The account page, the top-level sign-in and a projects stand-in.
Future<GoRouter> _pumpRoutes(
  WidgetTester tester, {
  required BackendSession session,
  required String initial,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.projects,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('projects')),
      ),
      GoRoute(
        path: RoutePaths.settingsAccount,
        builder: (BuildContext _, GoRouterState _) => const AccountRoute(),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (BuildContext _, GoRouterState _) => const SignInRoute(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        backendSessionProvider.overrideWith((Ref _) => session),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Lets the session's stores finish, pumping frames between.
Future<void> _settle(WidgetTester tester) async {
  for (int round = 0; round < 5; round++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}
