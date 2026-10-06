import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_media_reader.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/account/data/backend_proxy.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../../../support/processing_fixture.dart';

void main() {
  test('a fresh install extracts through the proxy with no key ever entered on '
      'the device', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open(
      plateText: 'GRUNDFOS 240V',
    );
    await fixture.addField('serial', required: true);
    final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
    final Map<SecretKey, String> vault = _enrolled(
      role: 'field_operator',
      grants: <String, Object?>{fixture.project.id: null},
      at: fixture.clock.nowUtc(),
    );
    final List<({String path, Map<String, Object?>? body})> sent =
        <({String path, Map<String, Object?>? body})>[];
    final BackendSession session = await _session(vault, fixture.clock, (
      String method,
      String path,
      Map<String, Object?>? body,
    ) {
      sent.add((path: path, body: body));
      return (
        status: 200,
        body: <String, Object?>{
          'text': jsonEncode(<String, Object?>{
            'fields': <String, Object?>{
              'serial': <String, Object?>{
                'value': 'SN458923',
                'confidence': 0.9,
                'evidence': <String>['photo:${photo.id}'],
              },
            },
          }),
          'model': 'default',
        },
      );
    });
    final ProxyAiService proxy = backendProxy(
      session,
      AiMediaReader(
        files: FileReader(storageRoot: fixture.storageRoot),
        storageRoot: fixture.storageRoot,
      ),
    );

    final ProcessingJob job = await fixture.job();
    final ProcessingStageWorker worker = fixture.worker(provider: proxy);
    for (final JobStage stage in JobStage.values) {
      await worker.perform(stage, job);
    }

    final ({String path, Map<String, Object?>? body}) extract = sent
        .singleWhere(
          (({String path, Map<String, Object?>? body}) call) =>
              call.path == '/api/v1/ai/extract',
        );
    expect(extract.body!['projectId'], fixture.project.id);
    final List<RecordField> fields = await fixture.db
        .select(fixture.db.recordFields)
        .get();
    expect(
      fields.where(
        (RecordField field) =>
            field.fieldKey == 'serial' && field.valueRaw == 'SN458923',
      ),
      hasLength(1),
    );
    expect(vault.keys, <SecretKey>[SecretKey.backendSession]);
    expect(vault.containsKey(SecretKey.providerCredential), isFalse);
    expect(jsonEncode(extract.body), isNot(contains('apiKey')));
  });

  test('an administrator’s unregistered project is registered, its grant '
      'refreshed and the call retried', () async {
    final DateTime now = DateTime.utc(2026, 9, 28);
    final List<String> calls = <String>[];
    var registered = false;
    final BackendSession session = await _session(
      _enrolled(role: 'administrator', grants: <String, Object?>{}, at: now),
      FixedClock(now),
      (String method, String path, Map<String, Object?>? body) {
        calls.add('$method $path');
        return switch (path) {
          '/api/v1/ai/ocr' when !registered => (
            status: 404,
            body: <String, Object?>{},
          ),
          '/api/v1/projects' => () {
            registered = true;
            return (status: 201, body: <String, Object?>{});
          }(),
          '/api/v1/auth/refresh' => (
            status: 200,
            body: <String, Object?>{
              'accessToken': 'next-access',
              'refreshToken': 'next-refresh',
            },
          ),
          '/api/v1/auth/me' => (
            status: 200,
            body: _identity('administrator', <String>['new-project'], now),
          ),
          _ => (
            status: 200,
            body: <String, Object?>{'text': 'Plate', 'model': 'default'},
          ),
        };
      },
    );
    final AiService proxy = _bound(session, 'new-project');
    expect(proxy.isAvailable, isTrue);

    final Result<ReadTextResult> read = await proxy.readText(
      const ReadTextRequest(imagePaths: <String>[]),
    );

    expect((read as Success<ReadTextResult>).value.text, 'Plate');
    expect(calls, <String>[
      'POST /api/v1/ai/ocr',
      'POST /api/v1/projects',
      'POST /api/v1/auth/refresh',
      'GET /api/v1/auth/me',
      'POST /api/v1/ai/ocr',
    ]);
    expect(session.config.grants.keys, contains('new-project'));
  });

  test(
    'a project registered to others leaves the proxy unavailable for it',
    () async {
      final DateTime now = DateTime.utc(2026, 9, 28);
      final List<String> calls = <String>[];
      final BackendSession session = await _session(
        _enrolled(role: 'administrator', grants: <String, Object?>{}, at: now),
        FixedClock(now),
        (String method, String path, Map<String, Object?>? body) {
          calls.add('$method $path');
          return (status: 404, body: <String, Object?>{});
        },
      );

      final Result<ReadTextResult> read = await _bound(
        session,
        'theirs',
      ).readText(const ReadTextRequest(imagePaths: <String>[]));

      final Failure failure = (read as FailureResult<ReadTextResult>).failure;
      expect(
        (failure as ProviderFailure).kind,
        ProviderFailureKind.authentication,
      );
      expect(calls, <String>['POST /api/v1/ai/ocr', 'POST /api/v1/projects']);
    },
  );

  test('a project manager is not offered the proxy for a project outside the '
      'grant', () async {
    final DateTime now = DateTime.utc(2026, 9, 28);
    final BackendSession session = await _session(
      _enrolled(
        role: 'project_manager',
        grants: <String, Object?>{'assigned': null},
        at: now,
      ),
      FixedClock(now),
      (String method, String path, Map<String, Object?>? body) =>
          throw StateError('no call is made for $path'),
    );

    expect(_bound(session, 'assigned').isAvailable, isTrue);
    expect(_bound(session, 'unassigned').isAvailable, isFalse);
    expect(_bound(session, '').isAvailable, isFalse);
  });
}

/// The proxy over [session], bound to [projectId] as the registry binds it.
AiService _bound(BackendSession session, String projectId) {
  return backendProxy(
    session,
    AiMediaReader(
      files: FileReader.memory(),
      storageRoot: StorageRoot.fake(documentsDirectory: Directory.systemTemp),
    ),
  ).forProject(projectId);
}

/// A saved enrolment for [role] over [grants], its grant running 30 days
/// from [at], with the organisation's AI provider configured.
Map<SecretKey, String> _enrolled({
  required String role,
  required Map<String, Object?> grants,
  required DateTime at,
}) {
  return <SecretKey, String>{
    SecretKey.backendSession: jsonEncode(<String, Object?>{
      'baseUrl': 'https://organisation.test',
      'accessToken': 'access',
      'refreshToken': 'refresh',
      'accountId': 'account',
      'role': role,
      'aiAvailable': true,
      'grants': grants,
      'grantValidUntil': at.add(const Duration(days: 30)).toIso8601String(),
    }),
  };
}

Map<String, Object?> _identity(
  String role,
  List<String> projects,
  DateTime at,
) {
  return <String, Object?>{
    'userId': 'account',
    'organisationId': 'organisation',
    'role': role,
    'aiAvailable': true,
    'grants': <Object?>[
      for (final String id in projects)
        <String, Object?>{'projectId': id, 'contextScope': null},
    ],
    'grantValidUntil': at.add(const Duration(days: 30)).toIso8601String(),
  };
}

/// A session restored from [vault] whose server answers through [answer].
Future<BackendSession> _session(
  Map<SecretKey, String> vault,
  Clock clock,
  ({int status, Map<String, Object?> body}) Function(
    String method,
    String path,
    Map<String, Object?>? body,
  )
  answer,
) async {
  final BackendSession session = BackendSession(
    storage: SecureStorage.fake(backing: vault),
    clock: clock,
    deviceId: 'device-a',
    send:
        ({
          required String method,
          required String path,
          Map<String, Object?>? body,
          String? token,
        }) async => answer(method, path, body),
  );
  await session.restore();
  addTearDown(session.dispose);
  return session;
}
