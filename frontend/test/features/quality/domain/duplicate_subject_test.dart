import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  final DateTime at = DateTime.utc(2026, 9, 28, 8);
  const Map<String, String> north = <String, String>{'site': 'North'};

  /// A probe that would fire every signal against a fully populated subject.
  List<DuplicateCandidate> rankAgainst(DuplicateSubject subject) {
    return rankDuplicateCandidates(
      recordId: 'probe',
      identity: 'hash-a',
      photoHashes: const <String>{'sha-1'},
      perceptualHashes: const <String>{'0000000000000000'},
      templateRowId: 'row-1',
      context: north,
      name: 'Pump',
      capturedAt: at,
      others: <DuplicateSubject>[subject],
    );
  }

  test('a subject with only an identity hash matches by identity alone', () {
    final List<DuplicateCandidate> ranked = rankAgainst(
      const DuplicateSubject(recordId: 'r', identityHash: 'hash-a'),
    );
    expect(ranked.single.signals, <DuplicateSignal>{DuplicateSignal.identity});
  });

  test('a subject with a different hash and default fields matches nothing', () {
    final List<DuplicateCandidate> ranked = rankAgainst(
      const DuplicateSubject(recordId: 'r', identityHash: 'hash-b'),
    );
    expect(ranked, isEmpty);
  });

  test('a subject with no capture time never fires the name signal', () {
    final List<DuplicateCandidate> ranked = rankAgainst(
      const DuplicateSubject(
        recordId: 'r',
        identityHash: 'hash-b',
        name: 'Pump',
        context: north,
      ),
    );
    expect(ranked, isEmpty);
  });

  test('a subject fires the name signal once it carries a capture time', () {
    final List<DuplicateCandidate> ranked = rankAgainst(
      DuplicateSubject(
        recordId: 'r',
        identityHash: 'hash-b',
        name: 'Pump',
        context: north,
        capturedAt: at,
      ),
    );
    expect(ranked.single.signals, <DuplicateSignal>{
      DuplicateSignal.nameContextTime,
    });
  });

  test('a subject with an empty context matches only an empty context', () {
    final List<DuplicateCandidate> ranked = rankAgainst(
      const DuplicateSubject(
        recordId: 'r',
        identityHash: 'hash-b',
        templateRowId: 'row-1',
      ),
    );
    expect(ranked, isEmpty);
    final List<DuplicateCandidate> unscoped = rankDuplicateCandidates(
      recordId: 'probe',
      identity: '',
      photoHashes: const <String>{},
      perceptualHashes: const <String>{},
      templateRowId: 'row-1',
      context: const <String, String>{},
      name: '',
      capturedAt: null,
      others: const <DuplicateSubject>[
        DuplicateSubject(
          recordId: 'r',
          identityHash: 'hash-b',
          templateRowId: 'row-1',
        ),
      ],
    );
    expect(unscoped.single.signals, <DuplicateSignal>{
      DuplicateSignal.predefinedRow,
    });
  });

  test('a subject holding every hash fires every photo signal', () {
    final List<DuplicateCandidate> ranked = rankAgainst(
      const DuplicateSubject(
        recordId: 'r',
        identityHash: 'hash-b',
        photoHashes: <String>{'sha-0', 'sha-1'},
        perceptualHashes: <String>{'0000000000000001'},
      ),
    );
    expect(ranked.single.signals, <DuplicateSignal>{
      DuplicateSignal.samePhoto,
      DuplicateSignal.nearPhoto,
    });
  });

  test('a subject compares its context without regard to case', () {
    final List<DuplicateCandidate> ranked = rankAgainst(
      const DuplicateSubject(
        recordId: 'r',
        identityHash: 'hash-b',
        templateRowId: 'row-1',
        context: <String, String>{'site': 'NORTH'},
      ),
    );
    expect(ranked.single.signals, <DuplicateSignal>{
      DuplicateSignal.predefinedRow,
    });
  });
}
