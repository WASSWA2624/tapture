import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 9, 28);
  Map<String, Object?> identity() => <String, Object?>{
    'userId': 'account',
    'organisationId': 'organisation',
    'role': 'field_operator',
    'grants': <Object?>[
      <String, Object?>{'projectId': 'project', 'contextScope': null},
    ],
    'grantValidUntil': now.add(const Duration(days: 30)).toIso8601String(),
  };

  test(
    'secure session survives restart offline without rewriting operator attribution',
    () async {
      final Map<SecretKey, String> secrets = <SecretKey, String>{};
      final Map<String, String> database = <String, String>{
        'operator': 'Original name',
      };
      var requests = 0;
      final BackendSession first = BackendSession(
        storage: SecureStorage.fake(backing: secrets, database: database),
        clock: FixedClock(now),
        deviceId: 'device',
        initialUrl: 'https://organisation.test',
        linkAccount: (String id) async {
          database['accountId'] = id;
        },
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async {
              requests++;
              if (path.endsWith('/login')) {
                return (
                  status: 200,
                  body: <String, Object?>{
                    'accessToken': 'access',
                    'refreshToken': 'refresh',
                  },
                );
              }
              return (status: 200, body: identity());
            },
      );
      expect(
        await first.signIn('operator@example.test', 'entered password'),
        isA<Success<void>>(),
      );
      expect(database, <String, String>{
        'operator': 'Original name',
        'accountId': 'account',
      });
      expect(secrets.keys, <SecretKey>[SecretKey.backendSession]);
      expect(secrets.values.single, isNot(contains('entered password')));
      await first.dispose();
      final BackendSession restored = BackendSession(
        storage: SecureStorage.fake(backing: secrets),
        clock: FixedClock(now.add(const Duration(days: 45))),
        deviceId: 'device',
        offline: () => true,
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async {
              fail('Offline restore must not contact a server');
            },
      );
      expect(await restored.restore(), isA<Success<void>>());
      expect(restored.config.state, EnrolmentState.enrolled);
      expect(restored.config.needsSignIn, isFalse);
      expect(restored.config.grants.keys, <String>['project']);
      expect(restored.canUseBackend, isFalse);
      expect(await restored.refresh(), isFalse);
      expect(requests, 2);
      await restored.dispose();
    },
  );

  test(
    'concurrent refreshes rotate once and save successor before failed identity fetch',
    () async {
      final Map<SecretKey, String> secrets = <SecretKey, String>{
        SecretKey.backendSession: jsonEncode(<String, Object?>{
          'baseUrl': 'https://organisation.test',
          'accessToken': 'old-access',
          'refreshToken': 'old-refresh',
          'accountId': 'account',
          'grantValidUntil': now
              .add(const Duration(days: 30))
              .toIso8601String(),
        }),
      };
      final Completer<void> rotated = Completer<void>();
      var calls = 0;
      final BackendSession session = BackendSession(
        storage: SecureStorage.fake(backing: secrets),
        clock: FixedClock(now),
        deviceId: 'device',
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async {
              if (path.endsWith('/refresh')) {
                calls++;
                await rotated.future;
                return (
                  status: 200,
                  body: <String, Object?>{
                    'accessToken': 'new-access',
                    'refreshToken': 'new-refresh',
                  },
                );
              }
              throw TimeoutException('unreachable');
            },
      );
      await session.restore();
      final Future<bool> first = session.refresh();
      final Future<bool> second = session.refresh();
      rotated.complete();
      expect(await first, isFalse);
      expect(await second, isFalse);
      expect(calls, 1);
      expect(secrets.values.single, contains('new-refresh'));
      expect(session.config.state, EnrolmentState.enrolled);
      expect(session.config.reachable, isFalse);
      await session.dispose();
    },
  );

  test(
    'server configuration rejects cleartext and credentials in URLs',
    () async {
      final BackendSession session = BackendSession(
        storage: SecureStorage.fake(backing: <SecretKey, String>{}),
        clock: FixedClock(now),
        deviceId: 'device',
      );
      for (final String url in <String>[
        'http://org.test',
        'https://password@org.test',
        'https://org.test?key=secret',
      ]) {
        expect(await session.configure(url, ''), isA<FailureResult<void>>());
      }
      expect(
        await session.configure('https://org.test', ''),
        isA<Success<void>>(),
      );
      await session.dispose();
    },
  );
}
