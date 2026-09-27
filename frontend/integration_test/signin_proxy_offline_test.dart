import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/backend/grant_cache.dart';
import 'package:tapture/core/backend/offline_authority.dart';
import 'package:tapture/core/errors/result.dart';
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

    final Map<String, String> secrets = <String, String>{};
    final GrantCache cache = GrantCache(
      secrets: secrets,
      now: () => app.clock.nowUtc(),
    );
    cache.save(
      accessToken: 'access',
      refreshToken: 'refresh',
      organisationId: 'org-1',
      refreshedAt: app.clock.nowUtc(),
    );
    app.clock.advance(const Duration(days: 45));
    final OfflineAuthority authority = OfflineAuthority(
      cache.read(at: app.clock.nowUtc()),
    );
    expect(authority.may(WorkCapability.capture), isTrue);
    expect(authority.may(WorkCapability.review), isTrue);
    expect(authority.may(WorkCapability.edit), isTrue);
    expect(authority.may(WorkCapability.export), isTrue);
    expect(authority.may(WorkCapability.relay), isFalse);
    expect(authority.refusal(WorkCapability.relay), isNotNull);
    expect(authority.may(WorkCapability.aiProxy), isFalse);
    expect(authority.refusal(WorkCapability.aiProxy), isNotNull);
    expect(authority.may(WorkCapability.roleChange), isFalse);
    expect(authority.refusal(WorkCapability.roleChange), isNotNull);
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
