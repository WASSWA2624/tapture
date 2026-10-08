import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/features/account/presentation/account_connection_panel.dart';
import 'package:tapture/features/account/presentation/account_session.dart';
import 'package:tapture/features/settings/presentation/settings_disclosure.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

void main() {
  testWidgets('mounting and revealing cached account never makes a request', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    final BackendSession session = await _session(() => calls++);
    final BackendConfig before = session.config;
    await _pump(tester, session);
    expect(find.text('person@example.test'), findsNothing);
    await tester.tap(find.text(Copy.aiServerAndAccount));
    await tester.pumpAndSettle();
    expect(find.text('person@example.test'), findsOneWidget);
    expect(find.byType(AppPage), findsNothing);
    expect(session.config, same(before));
    expect(calls, 0);
    await tester.tap(find.text(Copy.aiServerAndAccount));
    await tester.pumpAndSettle();
    expect(find.text('person@example.test'), findsNothing);
    expect(calls, 0);
  });

  testWidgets(
    'configuration is explicit, local and durable before showing status',
    (WidgetTester tester) async {
      int calls = 0;
      final BackendSession session = await _session(
        () => calls++,
        configured: false,
      );
      await _pump(tester, session);
      await tester.tap(find.text(Copy.aiServerAndAccount));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'https://new-organisation.test',
      );
      await tester.enterText(find.byType(TextField).last, 'organisation');
      await tester.tap(find.text(Copy.aiServerAndAccount));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      final ExcludeFocus hidden = tester.widget<ExcludeFocus>(
        find
            .descendant(
              of: find.byType(SettingsDisclosure),
              matching: find.byType(ExcludeFocus),
            )
            .first,
      );
      expect(hidden.excluding, isTrue);
      await tester.tap(find.text(Copy.aiServerAndAccount));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'https://new-organisation.test',
      );
      await tester.tap(find.widgetWithText(AppButton, Copy.backendConfigure));
      await tester.pumpAndSettle();
      expect(session.config.baseUrl, 'https://new-organisation.test');
      expect(find.text('https://new-organisation.test'), findsOneWidget);
      expect(calls, 0);
    },
  );

  testWidgets('disclosures with the same ID retain independent route state', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: Column(
          children: <Widget>[
            SettingsDisclosure(
              id: 'account',
              title: 'First',
              children: <Widget>[Text('First content')],
            ),
            SettingsDisclosure(
              id: 'account',
              title: 'Second',
              initiallyExpanded: true,
              children: <Widget>[Text('Second content')],
            ),
          ],
        ),
      ),
    );
    expect(find.text('First content'), findsNothing);
    expect(find.text('Second content'), findsOneWidget);
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    expect(find.text('First content'), findsOneWidget);
    expect(find.text('Second content'), findsOneWidget);
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();
    expect(find.text('First content'), findsOneWidget);
    expect(find.text('Second content'), findsNothing);
  });

  testWidgets(
    'failed configuration retains input across disclosure and layout changes',
    (WidgetTester tester) async {
      int calls = 0;
      final BackendSession session = await _session(
        () => calls++,
        configured: false,
      );
      await _pump(tester, session);
      await tester.tap(find.text(Copy.aiServerAndAccount));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'http://insecure.test',
      );
      await tester.enterText(find.byType(TextField).last, 'field-organisation');
      await tester.tap(find.widgetWithText(AppButton, Copy.backendConfigure));
      await tester.pumpAndSettle();
      expect(find.byType(AppBanner), findsOneWidget);
      expect(session.config.baseUrl, isEmpty);
      await tester.tap(find.text(Copy.aiServerAndAccount));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        session,
        locale: const Locale('en', 'XA'),
        cell: const ScreenMatrix(Size(1200, 800), 2, Brightness.dark, false),
      );
      final LocalizedCopy copy = Copy.of(
        tester.element(find.byType(SettingsDisclosure)),
      );
      await tester.tap(find.text(copy.aiServerAndAccount));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'http://insecure.test',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'field-organisation',
      );
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final ({String name, BackendConfig config, String message}) status
      in <({String name, BackendConfig config, String message})>[
        (
          name: 'unreachable',
          config: const BackendConfig(
            baseUrl: 'https://organisation.test',
            reachable: false,
          ),
          message: Copy.backendUnreachable,
        ),
        (
          name: 'revoked',
          config: const BackendConfig(
            baseUrl: 'https://organisation.test',
            state: EnrolmentState.revoked,
            reachable: false,
          ),
          message: Copy.backendRevoked,
        ),
        (
          name: 'expired',
          config: const BackendConfig(
            baseUrl: 'https://organisation.test',
            state: EnrolmentState.enrolled,
            reachable: false,
          ),
          message: Copy.backendGrantExpired,
        ),
      ]) {
    testWidgets(
      'inline ${status.name} account shows its cached authority without a request',
      (WidgetTester tester) async {
        int calls = 0;
        final BackendSession session = await _session(
          () => calls++,
          expired: status.name == 'expired',
        );
        await pumpApp(
          tester,
          const Scaffold(
            body: SingleChildScrollView(child: AccountConnectionPanel()),
          ),
          overrides: <Override>[
            backendSessionProvider.overrideWithValue(session),
            backendConfigProvider.overrideWith(
              (Ref _) => Stream<BackendConfig>.value(status.config),
            ),
          ],
        );
        await tester.pumpAndSettle();
        expect(find.text(status.message), findsOneWidget);
        expect(find.byType(AppBanner), findsOneWidget);
        expect(calls, 0);
      },
    );
  }

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    for (final Locale locale in <Locale>[
      const Locale('en'),
      const Locale('en', 'XA'),
    ]) {
      testWidgets(
        'cached account states fit ${cell.description} $locale',
        (WidgetTester tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = cell.size;
          tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
          addTearDown(() {
            tester.view.reset();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final SemanticsHandle semantics = tester.ensureSemantics();
          try {
            for (final _AccountStatus status in _AccountStatus.values) {
              // Each state starts with a fresh route-local disclosure and cache.
              await tester.pumpWidget(const SizedBox.shrink());
              int calls = 0;
              final BackendSession session = await _session(
                () => calls++,
                configured: status != _AccountStatus.unconfigured,
                signedIn: status != _AccountStatus.configured,
                expired: status == _AccountStatus.expired,
                revoked: status == _AccountStatus.revoked,
                offline: status == _AccountStatus.unconfigured,
              );
              final BackendConfig before = session.config;
              expect(
                session.canUseBackend,
                status == _AccountStatus.signedIn ||
                    status == _AccountStatus.unreachable,
                reason: 'valid cached sessions permit recorded transport',
              );
              await _pump(
                tester,
                session,
                locale: locale,
                cell: cell,
                config: status == _AccountStatus.unreachable
                    ? BackendConfig(
                        baseUrl: before.baseUrl,
                        organisationId: before.organisationId,
                        accountEmail: before.accountEmail,
                        accountId: before.accountId,
                        role: before.role,
                        state: before.state,
                        grantValidUntil: before.grantValidUntil,
                        reachable: false,
                      )
                    : null,
              );
              final LocalizedCopy copy = Copy.of(
                tester.element(find.byType(SettingsDisclosure)),
              );
              expect(calls, 0, reason: '${status.name} mount is cache-only');
              expect(find.byType(AccountConnectionPanel), findsNothing);
              await tester.tap(find.text(copy.aiServerAndAccount));
              await tester.pumpAndSettle();
              expect(calls, 0, reason: '${status.name} reveal is cache-only');
              final String? message = switch (status) {
                _AccountStatus.expired => copy.backendGrantExpired,
                _AccountStatus.revoked => copy.backendRevoked,
                _AccountStatus.unreachable => copy.backendUnreachable,
                _ => null,
              };
              expect(
                find.byType(AppBanner),
                message == null ? findsNothing : findsOneWidget,
                reason: status.name,
              );
              if (message != null) {
                expect(find.text(message), findsOneWidget, reason: status.name);
              }
              for (final Finder content in <Finder>[
                for (
                  int index = 0;
                  index < find.byType(AppListTile).evaluate().length;
                  index++
                )
                  find.byType(AppListTile).at(index),
                for (
                  int index = 0;
                  index < find.byType(TextField).evaluate().length;
                  index++
                )
                  find.byType(TextField).at(index),
              ]) {
                await Scrollable.ensureVisible(
                  tester.element(content),
                  alignment: .5,
                );
                await tester.pumpAndSettle();
                expect(
                  ScreenProbe.layoutIssues(tester),
                  isEmpty,
                  reason: '${status.name} account content stays readable',
                );
              }
              final String actionLabel = switch (status) {
                _AccountStatus.unconfigured => copy.backendConfigure,
                _AccountStatus.configured ||
                _AccountStatus.revoked => copy.signInAction,
                _ => copy.signOutAction,
              };
              final Finder action = find.widgetWithText(AppButton, actionLabel);
              await Scrollable.ensureVisible(
                tester.element(action),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              expect(action.hitTestable(), findsOneWidget, reason: status.name);
              expect(action, meetsTapTarget(), reason: status.name);
              expect(
                action,
                hasSemanticLabel(actionLabel),
                reason: status.name,
              );
              expect(tester.widget<AppButton>(action).variant, switch (status) {
                _AccountStatus.unconfigured ||
                _AccountStatus.configured ||
                _AccountStatus.revoked => AppButtonVariant.secondary,
                _ => AppButtonVariant.destructive,
              }, reason: status.name);
              if (status != _AccountStatus.unconfigured) {
                expect(find.text(before.baseUrl), findsOneWidget);
                expect(
                  find.text('person@example.test'),
                  status == _AccountStatus.configured
                      ? findsNothing
                      : findsOneWidget,
                );
              }
              await expectNoA11yIssues(tester);
              expect(tester.takeException(), isNull, reason: status.name);
              await Scrollable.ensureVisible(
                tester.element(find.text(copy.aiServerAndAccount)),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              await tester.tap(find.text(copy.aiServerAndAccount));
              await tester.pumpAndSettle();
              expect(find.byType(AccountConnectionPanel), findsNothing);
              expect(session.config, same(before), reason: status.name);
              expect(calls, 0, reason: '${status.name} collapse is cache-only');
            }
          } finally {
            semantics.dispose();
          }
        },
        variant: TargetPlatformVariant.all(),
      );
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  BackendSession session, {
  Locale? locale,
  ScreenMatrix? cell,
  BackendConfig? config,
}) async {
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (BuildContext context) => SingleChildScrollView(
          child: SettingsDisclosure(
            id: 'ai-account',
            title: Copy.of(context).aiServerAndAccount,
            maintainState: true,
            children: const <Widget>[AccountConnectionPanel()],
          ),
        ),
      ),
    ),
    locale: locale,
    brightness: cell?.brightness ?? Brightness.light,
    outdoor: cell?.outdoor ?? false,
    overrides: <Override>[
      backendSessionProvider.overrideWithValue(session),
      if (config != null)
        backendConfigProvider.overrideWith(
          (Ref _) => Stream<BackendConfig>.value(config),
        ),
    ],
  );
  await tester.pumpAndSettle();
}

Future<BackendSession> _session(
  VoidCallback onRequest, {
  bool configured = true,
  bool signedIn = true,
  bool expired = false,
  bool revoked = false,
  bool offline = true,
}) async {
  final DateTime now = DateTime.utc(2026, 10, 8);
  final BackendSession session = BackendSession(
    storage: SecureStorage.fake(
      backing: <SecretKey, String>{
        SecretKey.backendSession: jsonEncode(<String, Object?>{
          'baseUrl': configured ? 'https://organisation.test' : '',
          if (configured && signedIn) ...<String, Object?>{
            if (!revoked) ...<String, Object?>{
              'accessToken': 'access',
              'refreshToken': 'refresh',
            },
            if (revoked) 'state': EnrolmentState.revoked.name,
            'accountId': 'account',
            'accountEmail': 'person@example.test',
            'role': 'field_operator',
            'grantValidUntil': now
                .add(Duration(days: expired ? -1 : 30))
                .toIso8601String(),
          },
        }),
      },
    ),
    clock: FixedClock(now),
    deviceId: 'device',
    offline: () => offline,
    send:
        ({
          required String method,
          required String path,
          Map<String, Object?>? body,
          String? token,
        }) async {
          onRequest();
          return (status: 503, body: <String, Object?>{});
        },
  );
  await session.restore();
  addTearDown(session.dispose);
  return session;
}

enum _AccountStatus {
  unconfigured,
  configured,
  signedIn,
  expired,
  revoked,
  unreachable,
}
