import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  test('identity hashes ignore spacing, case and punctuation', () {
    const List<String> keys = <String>['serial'];
    final String a = identityHash(const <String, Object?>{
      'serial': 'ABB-1234',
    }, keys);
    final String b = identityHash(const <String, Object?>{
      'serial': 'abb 1234',
    }, keys);
    final String c = identityHash(const <String, Object?>{
      'serial': 'abb1234',
    }, keys);
    expect(a, b);
    expect(a, c);
    expect(
      identityHash(const <String, Object?>{'serial': 'ABB-1235'}, keys),
      isNot(a),
    );
  });

  test('each duplicate signal ranks, and a stronger signal comes first', () {
    final DateTime at = DateTime.utc(2026, 9, 27, 8);
    final List<DuplicateCandidate> ranked = rankDuplicateCandidates(
      recordId: 'new',
      identity: 'hash-a',
      photoHashes: const <String>{'photo-a'},
      perceptualHashes: const <String>{'aaaaaaaaaaaaaaaa'},
      templateRowId: 'row-1',
      context: const <String, String>{'site': 'North'},
      name: 'Pump',
      capturedAt: at,
      others: <DuplicateSubject>[
        const DuplicateSubject(
          recordId: 'by-name',
          identityHash: 'other',
          context: <String, String>{'site': 'North'},
          name: 'Pump',
        ),
        DuplicateSubject(
          recordId: 'by-name-time',
          identityHash: 'other',
          context: const <String, String>{'site': 'North'},
          name: 'Pump',
          capturedAt: at.add(const Duration(hours: 1)),
        ),
        const DuplicateSubject(
          recordId: 'by-row',
          identityHash: 'other',
          templateRowId: 'row-1',
          context: <String, String>{'site': 'North'},
        ),
        const DuplicateSubject(
          recordId: 'by-photo',
          identityHash: 'other',
          photoHashes: <String>{'photo-a'},
        ),
        const DuplicateSubject(recordId: 'by-identity', identityHash: 'hash-a'),
      ],
    );
    expect(
      ranked.map((DuplicateCandidate row) => row.recordId).first,
      'by-identity',
    );
    expect(
      ranked
          .firstWhere((DuplicateCandidate row) => row.recordId == 'by-photo')
          .signals,
      contains(DuplicateSignal.samePhoto),
    );
    expect(
      ranked
          .firstWhere((DuplicateCandidate row) => row.recordId == 'by-row')
          .signals,
      contains(DuplicateSignal.predefinedRow),
    );
    expect(
      ranked
          .firstWhere(
            (DuplicateCandidate row) => row.recordId == 'by-name-time',
          )
          .signals,
      contains(DuplicateSignal.nameContextTime),
    );
    expect(
      ranked.any((DuplicateCandidate row) => row.recordId == 'by-name'),
      isFalse,
    );
  });

  test('a formatting difference is not a conflict and a real one is', () {
    expect(
      ConflictDetection.find(<String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[
          const ValueCandidate(ValueSource.ocr, 'ABB-1234', 0.9, 'p1'),
          const ValueCandidate(ValueSource.barcode, 'abb 1234', 0.8, 'p2'),
        ],
      }),
      isEmpty,
    );
    final List<FieldConflict> conflicts = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[
          const ValueCandidate(ValueSource.ocr, 'ABB-1234', 0.9, 'p1'),
          const ValueCandidate(ValueSource.barcode, 'ABB-9999', 0.4, 'p2'),
        ],
      },
    );
    expect(conflicts.single.fieldKey, 'serial');
    expect(conflicts.single.candidates, hasLength(2));
  });

  test('variance matches the normalised value and flags a real change', () {
    final List<FieldVariance> rows = VarianceComputation.compare(
      recorded: const <String, Object?>{
        'serial': 'ABB-1234',
        'note': 'Worn',
        'gone': 'Yes',
      },
      found: const <String, Object?>{
        'serial': 'abb 1234',
        'note': 'New',
        'gone': '',
      },
      fieldKeys: const <String>['serial', 'note', 'gone'],
    );
    expect(rows[0].status, VarianceStatus.match);
    expect(rows[1].status, VarianceStatus.changed);
    expect(rows[2].status, VarianceStatus.missing);
  });

  test('missing items are the register and checklist rows never captured', () {
    final MissingItems missing = MissingItems.compute(
      registerIds: const <String>['a', 'b', 'c'],
      capturedRegisterIds: const <String>{'b'},
      checklistIds: const <String>['row-1', 'row-2'],
      capturedChecklistIds: const <String>{'row-1'},
    );
    expect(missing.registerNotFound, <String>['a', 'c']);
    expect(missing.checklistNotCaptured, <String>['row-2']);
  });

  test('a matched row prefills and keeps the register value', () {
    final VerificationPrefill matched = VerificationPrefill.fromRow(
      row: const <String, String>{'asset': 'ABB-1'},
      binding: const <String, String>{'serial': 'asset'},
    );
    expect(matched.onRegister, isTrue);
    expect(matched.asRecorded['serial'], 'ABB-1');
    final Map<String, String> edited = Map<String, String>.of(matched.asFound);
    edited['serial'] = 'ABB-2';
    expect(matched.asRecorded['serial'], 'ABB-1');
    expect(edited['serial'], 'ABB-2');
  });

  test('an unmatched identifier is not on the register', () {
    final VerificationPrefill missed = VerificationPrefill.fromRow(
      row: null,
      binding: const <String, String>{'serial': 'asset'},
    );
    expect(missed.onRegister, isFalse);
    expect(missed.asRecorded, isEmpty);
  });

  test(
    'override keeps the replaced value in history and writes an audit row',
    () {
      final _Ledger ledger = _Ledger();
      DuplicateOverride.apply(
        ledger: ledger,
        leftId: 'old',
        rightId: 'new',
        person: 'Ann',
        previous: const <String, String>{'serial': 'A-1'},
        next: const <String, String>{'serial': 'A-2'},
        photoHashes: const <String>['photo-1'],
      );
      expect(ledger.values.single.previous, 'A-1');
      expect(ledger.values.single.next, 'A-2');
      expect(ledger.photos, <String>['photo-1']);
      expect(ledger.audits.single.action, 'override');
      expect(ledger.audits.single.person, 'Ann');
    },
  );

  test('keeping both links the pair without overwriting a value', () {
    final _Ledger ledger = _Ledger();
    DuplicateLink.keepBoth(ledger: ledger, a: 'b', b: 'a', person: 'Ann');
    expect(ledger.values, isEmpty);
    expect(ledger.audits.single.leftId, 'a');
    expect(ledger.audits.single.rightId, 'b');
    expect(ledger.audits.single.action, 'link');
  });
}

final class _Ledger implements DuplicateLedger {
  final List<({String? previous, String next})> values =
      <({String? previous, String next})>[];
  final List<String> photos = <String>[];
  final List<({String action, String leftId, String rightId, String person})>
  audits = <({String action, String leftId, String rightId, String person})>[];

  @override
  void addAudit({
    required String action,
    required String leftId,
    required String rightId,
    required String person,
    required String detail,
  }) {
    audits.add((
      action: action,
      leftId: leftId,
      rightId: rightId,
      person: person,
    ));
  }

  @override
  void attachPhoto(String sha256) {
    photos.add(sha256);
  }

  @override
  void replaceValue({
    required String fieldKey,
    required String? previous,
    required String next,
  }) {
    values.add((previous: previous, next: next));
  }
}
