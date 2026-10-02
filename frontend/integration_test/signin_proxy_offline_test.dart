import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/features/account/domain/offline_authority.dart';
import 'package:tapture/features/account/domain/role_gate.dart';
import 'package:tapture/features/account/presentation/account_session.dart';
import 'package:tapture/features/records/domain/record_entry.dart';

import 'support/harness.dart';

void main() {
  test('sign-in once, then capture and export with the server away', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    expect(app.backend.signIn(), isTrue);
    expect(app.backend.holdsProviderKey, isFalse);
    final Result<ExtractFieldsResult> extracted = await app.ai.extractFields(
      const ExtractFieldsRequest(
        templateLabel: 'Meters',
        fieldLabels: <String>['serial'],
        ocrText: '',
        transcripts: <String>[],
        captions: <String>[],
        imagePaths: <String>['photo.jpg'],
      ),
    );
    expect(extracted, isA<Success<ExtractFieldsResult>>());
    expect(app.ai.calls, 1);
    app.backend.markUnreachable();
    final RecordEntry captured = await app.capture(
      fields: const <String, String>{'serial': 'OFF-1'},
    );
    final RecordEntry approved = await app.approve(captured.id);
    expect(approved.valueOf('serial')?.display, 'OFF-1');
    expect(
      app.csvFor(<ExportRecord>[app.rowOf(approved)]).contains('OFF-1'),
      isTrue,
    );
    expect(app.backend.signIn(), isFalse);
    expect(app.outboundCallCount, 0);

    // A session saved at sign-in, restored with no network, past its grant.
    final BackendSession session = BackendSession(
      storage: SecureStorage.fake(
        backing: <SecretKey, String>{
          SecretKey.backendSession: jsonEncode(<String, Object?>{
            'baseUrl': 'https://organisation.test',
            'accessToken': 'access',
            'refreshToken': 'refresh',
            'accountId': 'account',
            'role': 'project_manager',
            'grants': <String, Object?>{'project': null},
            'grantValidUntil': app.clock
                .nowUtc()
                .add(const Duration(days: 30))
                .toIso8601String(),
          }),
        },
      ),
      clock: app.clock,
      deviceId: 'device',
      offline: () => true,
    );
    addTearDown(session.dispose);
    await session.restore();
    app.clock.advance(const Duration(days: 45));
    final OfflineAuthority authority = authorityFor(
      session,
      projectId: 'project',
    );
    expect(authority.state, AuthorityState.cachedExpired);
    expect(session.config.needsSignIn, isFalse);
    expect(authority.may(RoleCapability.capture), isTrue);
    expect(authority.may(RoleCapability.review), isTrue);
    expect(authority.may(RoleCapability.export), isTrue);
    for (final RoleCapability serverBound in <RoleCapability>[
      RoleCapability.relay,
      RoleCapability.aiProxy,
      RoleCapability.manageMembers,
    ]) {
      expect(authority.may(serverBound), isFalse);
      expect(authority.refusal(serverBound), AuthorityRefusal.grantExpired);
    }
    final RecordEntry later = await app.capture(
      fields: const <String, String>{'serial': 'OFF-2'},
    );
    expect(later.valueOf('serial')?.raw, 'OFF-2');
    app.backend.markReachable();
    expect(app.backend.signIn(), isTrue);
    expect(app.backend.signIns, 2);
    expect(app.backend.holdsProviderKey, isFalse);
  });
}
