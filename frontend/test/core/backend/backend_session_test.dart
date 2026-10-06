import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show QueryRow, Table, TableInfo;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_api_client.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/logging/log_export.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';

import '../../support/bundle_fixture.dart';
import '../../support/secret_patterns.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 9, 28);
  Map<String, Object?> identity({String organisation = 'organisation'}) =>
      <String, Object?>{
        'userId': 'account',
        'organisationId': organisation,
        'role': 'field_operator',
        'grants': <Object?>[
          <String, Object?>{'projectId': 'project', 'contextScope': null},
        ],
        'grantValidUntil': now.add(const Duration(days: 30)).toIso8601String(),
      };

  /// A saved, enrolled session whose grant runs 30 days from [now].
  Map<SecretKey, String> enrolled() => <SecretKey, String>{
    SecretKey.backendSession: jsonEncode(<String, Object?>{
      'baseUrl': 'https://organisation.test',
      'accessToken': 'old-access',
      'refreshToken': 'old-refresh',
      'accountId': 'account',
      'role': 'field_operator',
      'grantValidUntil': now.add(const Duration(days: 30)).toIso8601String(),
    }),
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
      expect(first.authority, AuthorityState.fresh);
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
      expect(restored.authority, AuthorityState.cachedExpired);
      expect(restored.canUseBackend, isFalse);
      expect(await restored.refresh(), isFalse);
      expect(requests, 2);
      await restored.dispose();
    },
  );

  test(
    'sign-in moves through enrolling to enrolled, and a refused one back to not enrolled',
    () async {
      var accept = false;
      final BackendSession session = BackendSession(
        storage: SecureStorage.fake(backing: <SecretKey, String>{}),
        clock: FixedClock(now),
        deviceId: 'device',
        initialUrl: 'https://organisation.test',
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async {
              if (path.endsWith('/login')) {
                return accept
                    ? (
                        status: 200,
                        body: <String, Object?>{
                          'accessToken': 'access',
                          'refreshToken': 'refresh',
                        },
                      )
                    : (status: 401, body: <String, Object?>{});
              }
              return (status: 200, body: identity());
            },
      );
      final List<EnrolmentState> seen = <EnrolmentState>[];
      final StreamSubscription<BackendConfig> watching = session.changes.listen(
        (BackendConfig config) => seen.add(config.state),
      );

      final Result<void> refused = await session.signIn('a@b.test', 'wrong');
      expect(
        (refused as FailureResult<void>).failure,
        BackendApiClient.notAccepted,
      );
      accept = true;
      expect(await session.signIn('a@b.test', 'right'), isA<Success<void>>());
      await Future<void>.delayed(Duration.zero);

      expect(seen, <EnrolmentState>[
        EnrolmentState.enrolling,
        EnrolmentState.notEnrolled,
        EnrolmentState.enrolling,
        EnrolmentState.enrolled,
      ]);
      await watching.cancel();
      await session.dispose();
    },
  );

  test(
    'a revoked device becomes revoked and needs sign-in instead of showing unreachable',
    () async {
      final Map<SecretKey, String> secrets = enrolled();
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
            }) async => (status: 401, body: <String, Object?>{}),
      );
      await session.restore();
      expect(session.canUseBackend, isTrue);

      expect(await session.refresh(), isFalse);

      expect(session.config.state, EnrolmentState.revoked);
      expect(session.config.needsSignIn, isTrue);
      expect(session.config.reachable, isTrue);
      expect(session.config.accountId, 'account');
      expect(session.authority, AuthorityState.cachedExpired);
      expect(session.canUseBackend, isFalse);
      expect(secrets.values.single, isNot(contains('old-refresh')));
      await session.dispose();

      final BackendSession restarted = BackendSession(
        storage: SecureStorage.fake(backing: secrets),
        clock: FixedClock(now),
        deviceId: 'device',
      );
      await restarted.restore();
      expect(restarted.config.state, EnrolmentState.revoked);
      expect(restarted.config.needsSignIn, isTrue);
      await restarted.dispose();
    },
  );

  test(
    'concurrent refreshes rotate once and save successor before failed identity fetch',
    () async {
      final Map<SecretKey, String> secrets = enrolled();
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

  group('credentials', () {
    late Logger previous;

    setUp(() {
      previous = Logger.current;
    });

    tearDown(() {
      Logger.current = previous;
    });

    test(
      'no token or organisation id reaches the database, a log or an export',
      () async {
        const String access = 'planted-access-token-5e1f';
        const String refresh = 'planted-refresh-token-9a2c';
        const String rotated = 'planted-rotated-token-77b0';
        const String organisation = 'planted-organisation-3d4e';
        final Logger logger = Logger();
        Logger.current = logger;
        final BundleFixture fixture = await seedProjectForBundle();
        addTearDown(() async {
          await fixture.db.close();
          if (fixture.root.parent.existsSync()) {
            fixture.root.parent.deleteSync(recursive: true);
          }
        });
        final FixedClock clock = FixedClock(now);
        final Map<SecretKey, String> vault = <SecretKey, String>{};
        final BackendSession session = BackendSession(
          storage: SecureStorage.fake(backing: vault),
          clock: clock,
          deviceId: 'device-test',
          initialUrl: 'https://organisation.test',
          linkAccount: (String id) => linkDeviceAccount(
            fixture.db,
            deviceId: 'device-test',
            accountId: id,
            clock: clock,
          ),
          send:
              ({
                required String method,
                required String path,
                Map<String, Object?>? body,
                String? token,
              }) async {
                logger.info('backend', '$method $path');
                if (path.endsWith('/login')) {
                  return (
                    status: 200,
                    body: <String, Object?>{
                      'accessToken': access,
                      'refreshToken': refresh,
                    },
                  );
                }
                if (path.endsWith('/refresh')) {
                  return (
                    status: 200,
                    body: <String, Object?>{
                      'accessToken': rotated,
                      'refreshToken': rotated,
                    },
                  );
                }
                if (path.endsWith('/logout')) {
                  return (status: 204, body: <String, Object?>{});
                }
                return (
                  status: 200,
                  body: identity(organisation: organisation),
                );
              },
        );
        expect(
          await session.signIn('a@b.test', 'entered password'),
          isA<Success<void>>(),
        );
        expect(await session.refresh(), isTrue);
        expect(vault.values.single, contains(organisation));
        expect(await session.signOut(), isA<Success<void>>());
        await session.dispose();

        final ExportedPackage exported = _ok(
          await ExportRepositoryImpl(
            db: fixture.db,
            storageRoot: fixture.storageRoot,
            clock: clock,
            deviceId: 'device-test',
            ids: UuidV7Service.sequence(clock),
            templates: TemplateRepositoryImpl(
              db: fixture.db,
              clock: clock,
              deviceId: 'device-test',
              ids: UuidV7Service.sequence(clock),
            ),
          ).exportProject(fixture.projectId, cancel: CancellationToken()),
        );
        final File package = File(
          '${fixture.root.path}/'
          '${(exported.package as StoredBundle).relativePath}',
        );
        final File log = _ok(
          await exportLog(into: Directory('${fixture.root.parent.path}/logs')),
        );

        final List<({String name, RegExp pattern})> planted =
            SecretScan.compile(
              '',
              secrets: const <String>[
                access,
                refresh,
                rotated,
                organisation,
                'entered password',
              ],
            );
        expect(logger.buffer, isNotEmpty);
        expect(SecretScan.scanFile(log, planted), isEmpty);
        expect(SecretScan.scanFile(package, planted), isEmpty);
        for (final TableInfo<Table, Object?> table in fixture.db.allTables) {
          for (final QueryRow row
              in await fixture.db
                  .customSelect('SELECT * FROM ${table.actualTableName}')
                  .get()) {
            final String values = row.data.values.join('\u0000');
            for (final String secret in <String>[
              access,
              refresh,
              rotated,
              organisation,
            ]) {
              expect(
                values,
                isNot(contains(secret)),
                reason: table.actualTableName,
              );
            }
          }
        }
      },
    );
  });
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}
