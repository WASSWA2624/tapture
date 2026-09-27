import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/domain/duplicate_candidate.dart';
import 'package:tapture/features/quality/domain/duplicate_detection.dart';
import 'package:tapture/features/quality/domain/duplicate_ledger.dart';
import 'package:tapture/features/quality/domain/duplicate_override.dart';
import 'package:tapture/features/quality/domain/duplicate_subject.dart';
import 'package:tapture/features/quality/domain/identity_hash.dart';
import 'package:tapture/features/records/domain/record_entry.dart';

import '../test/support/matchers.dart';
import 'support/harness.dart';

void main() {
  test('an overridden duplicate keeps both records and the reason', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    final String identity = identityHash(
      const <String, Object?>{'serial': 'ABB-1234'},
      const <String>['serial'],
    );
    final RecordEntry first = await app.capture(
      fields: const <String, String>{'serial': 'ABB-1234'},
    );
    final RecordEntry second = await app.capture(
      fields: const <String, String>{'serial': 'abb 1234'},
    );
    final List<DuplicateCandidate> found = rankDuplicateCandidates(
      recordId: second.id,
      identity: identity,
      photoHashes: const <String>{},
      perceptualHashes: const <String>{},
      templateRowId: null,
      context: const <String, String>{},
      name: 'ABB-1234',
      capturedAt: app.clock.nowUtc(),
      others: <DuplicateSubject>[
        DuplicateSubject(recordId: first.id, identityHash: identity),
      ],
    );
    expect(found, isNotEmpty);
    final _Ledger ledger = _Ledger();
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: first.id,
      rightId: second.id,
      person: 'Ada',
      previous: const <String, String>{'serial': 'ABB-1234'},
      next: const <String, String>{'serial': 'ABB-1234-B'},
      photoHashes: const <String>[],
    );
    expect(valueOf(await app.records.byId(first.id)), isNotNull);
    expect(valueOf(await app.records.byId(second.id)), isNotNull);
    expect(ledger.person, 'Ada');
    expect(ledger.previous, 'ABB-1234');
    expect(ledger.next, 'ABB-1234-B');
    expect(valueOf(await app.records.byId(first.id))?.id, first.id);
    expect(ledger.detail, 'override');
    expect(app.outboundCallCount, 0);
  });
}

final class _Ledger implements DuplicateLedger {
  String? previous;
  String? next;
  String? person;
  String? detail;

  @override
  void replaceValue({
    required String fieldKey,
    required String? previous,
    required String next,
  }) {
    this.previous = previous;
    this.next = next;
  }

  @override
  void attachPhoto(String sha256) {}

  @override
  void addAudit({
    required String action,
    required String leftId,
    required String rightId,
    required String person,
    required String detail,
  }) {
    this.person = person;
    this.detail = detail;
  }
}
