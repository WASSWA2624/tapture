import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/quality/quality.dart';

/// Ranks [others] against a probe whose only set inputs are the named ones.
List<DuplicateCandidate> _rank({
  String recordId = 'new',
  String identity = '',
  Set<String> photoHashes = const <String>{},
  Set<String> perceptualHashes = const <String>{},
  String? templateRowId,
  Map<String, String> context = const <String, String>{},
  String name = '',
  DateTime? capturedAt,
  required List<DuplicateSubject> others,
}) {
  return rankDuplicateCandidates(
    recordId: recordId,
    identity: identity,
    photoHashes: photoHashes,
    perceptualHashes: perceptualHashes,
    templateRowId: templateRowId,
    context: context,
    name: name,
    capturedAt: capturedAt,
    others: others,
  );
}

Set<DuplicateSignal> _signalsOf(List<DuplicateCandidate> ranked, String id) {
  return ranked.firstWhere((DuplicateCandidate c) => c.recordId == id).signals;
}

void main() {
  final DateTime at = DateTime.utc(2026, 9, 27, 8);
  const Map<String, String> north = <String, String>{'site': 'North'};

  test('each duplicate signal ranks, and a stronger signal comes first', () {
    final List<DuplicateCandidate> ranked = _rank(
      identity: 'hash-a',
      photoHashes: const <String>{'photo-a'},
      perceptualHashes: const <String>{'aaaaaaaaaaaaaaaa'},
      templateRowId: 'row-1',
      context: north,
      name: 'Pump',
      capturedAt: at,
      others: <DuplicateSubject>[
        const DuplicateSubject(
          recordId: 'by-name',
          identityHash: 'other',
          context: north,
          name: 'Pump',
        ),
        DuplicateSubject(
          recordId: 'by-name-time',
          identityHash: 'other',
          context: north,
          name: 'Pump',
          capturedAt: at.add(const Duration(hours: 1)),
        ),
        const DuplicateSubject(
          recordId: 'by-row',
          identityHash: 'other',
          templateRowId: 'row-1',
          context: north,
        ),
        const DuplicateSubject(
          recordId: 'by-photo',
          identityHash: 'other',
          photoHashes: <String>{'photo-a'},
        ),
        const DuplicateSubject(recordId: 'by-identity', identityHash: 'hash-a'),
      ],
    );
    expect(ranked.first.recordId, 'by-identity');
    expect(_signalsOf(ranked, 'by-photo'), contains(DuplicateSignal.samePhoto));
    expect(
      _signalsOf(ranked, 'by-row'),
      contains(DuplicateSignal.predefinedRow),
    );
    expect(
      _signalsOf(ranked, 'by-name-time'),
      contains(DuplicateSignal.nameContextTime),
    );
    expect(
      ranked.any((DuplicateCandidate row) => row.recordId == 'by-name'),
      isFalse,
    );
  });

  group('identity', () {
    test('an equal stored hash fires', () {
      final List<DuplicateCandidate> ranked = _rank(
        identity: 'hash-a',
        others: const <DuplicateSubject>[
          DuplicateSubject(recordId: 'r', identityHash: 'hash-a'),
        ],
      );
      expect(_signalsOf(ranked, 'r'), <DuplicateSignal>{
        DuplicateSignal.identity,
      });
    });

    test('two records with no identity never match on it', () {
      final List<DuplicateCandidate> ranked = _rank(
        identity: '',
        others: const <DuplicateSubject>[
          DuplicateSubject(recordId: 'r', identityHash: ''),
        ],
      );
      expect(ranked, isEmpty);
    });
  });

  group('same photo', () {
    test('one shared content hash among several fires', () {
      final List<DuplicateCandidate> ranked = _rank(
        photoHashes: const <String>{'sha-1', 'sha-2'},
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            photoHashes: <String>{'sha-9', 'sha-2'},
          ),
        ],
      );
      expect(_signalsOf(ranked, 'r'), <DuplicateSignal>{
        DuplicateSignal.samePhoto,
      });
    });

    test('no shared content hash is silent', () {
      final List<DuplicateCandidate> ranked = _rank(
        photoHashes: const <String>{'sha-1'},
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            photoHashes: <String>{'sha-2'},
          ),
        ],
      );
      expect(ranked, isEmpty);
    });
  });

  group('near photo', () {
    test('a perceptual hash inside the distance budget fires', () {
      final List<DuplicateCandidate> ranked = _rank(
        perceptualHashes: const <String>{'0000000000000000'},
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            perceptualHashes: <String>{'0000000000000003'},
          ),
        ],
      );
      expect(_signalsOf(ranked, 'r'), <DuplicateSignal>{
        DuplicateSignal.nearPhoto,
      });
    });

    test('a perceptual hash outside the distance budget is silent', () {
      expect(AppConstants.processing.perceptualHashDistance, lessThan(64));
      final List<DuplicateCandidate> ranked = _rank(
        perceptualHashes: const <String>{'0000000000000000'},
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            perceptualHashes: <String>{'ffffffffffffffff'},
          ),
        ],
      );
      expect(ranked, isEmpty);
    });

    test('an empty perceptual hash never matches', () {
      final List<DuplicateCandidate> ranked = _rank(
        perceptualHashes: const <String>{''},
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            perceptualHashes: <String>{''},
          ),
        ],
      );
      expect(ranked, isEmpty);
    });
  });

  group('predefined row', () {
    test('the same row in the same context fires', () {
      final List<DuplicateCandidate> ranked = _rank(
        templateRowId: 'row-1',
        context: north,
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            templateRowId: 'row-1',
            context: <String, String>{'site': 'north'},
          ),
        ],
      );
      expect(_signalsOf(ranked, 'r'), <DuplicateSignal>{
        DuplicateSignal.predefinedRow,
      });
    });

    test('the same row in another context is silent', () {
      final List<DuplicateCandidate> ranked = _rank(
        templateRowId: 'row-1',
        context: north,
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            templateRowId: 'row-1',
            context: <String, String>{'site': 'South'},
          ),
        ],
      );
      expect(ranked, isEmpty);
    });

    test('a record captured from no row is silent', () {
      final List<DuplicateCandidate> ranked = _rank(
        templateRowId: '',
        context: north,
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            templateRowId: '',
            context: north,
          ),
        ],
      );
      expect(ranked, isEmpty);
    });
  });

  group('name, context and time', () {
    test('the same name in the same context inside the window fires', () {
      final List<DuplicateCandidate> ranked = _rank(
        name: 'Pump-1',
        context: north,
        capturedAt: at,
        others: <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            name: 'pump 1',
            context: north,
            capturedAt: at.add(AppConstants.merge.duplicateWindow),
          ),
        ],
      );
      expect(_signalsOf(ranked, 'r'), <DuplicateSignal>{
        DuplicateSignal.nameContextTime,
      });
    });

    test('the same name outside the window is silent', () {
      final List<DuplicateCandidate> ranked = _rank(
        name: 'Pump',
        context: north,
        capturedAt: at,
        others: <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            name: 'Pump',
            context: north,
            capturedAt: at.add(
              AppConstants.merge.duplicateWindow + const Duration(seconds: 1),
            ),
          ),
        ],
      );
      expect(ranked, isEmpty);
    });

    test('the same name in another context is silent', () {
      final List<DuplicateCandidate> ranked = _rank(
        name: 'Pump',
        context: north,
        capturedAt: at,
        others: <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            name: 'Pump',
            context: const <String, String>{'site': 'South'},
            capturedAt: at,
          ),
        ],
      );
      expect(ranked, isEmpty);
    });

    test('a blank name is silent', () {
      final List<DuplicateCandidate> ranked = _rank(
        name: '   ',
        context: north,
        capturedAt: at,
        others: <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'r',
            identityHash: 'other',
            name: '   ',
            context: north,
            capturedAt: at,
          ),
        ],
      );
      expect(ranked, isEmpty);
    });
  });

  group('ranking', () {
    test('candidates are ordered by score, strongest first', () {
      final List<DuplicateCandidate> ranked = _rank(
        identity: 'hash-a',
        photoHashes: const <String>{'sha-1'},
        templateRowId: 'row-1',
        context: north,
        others: const <DuplicateSubject>[
          DuplicateSubject(
            recordId: 'row-only',
            identityHash: 'other',
            templateRowId: 'row-1',
            context: north,
          ),
          DuplicateSubject(recordId: 'identity-only', identityHash: 'hash-a'),
          DuplicateSubject(
            recordId: 'photo-only',
            identityHash: 'other',
            photoHashes: <String>{'sha-1'},
          ),
        ],
      );
      expect(ranked.map((DuplicateCandidate c) => c.recordId), <String>[
        'identity-only',
        'photo-only',
        'row-only',
      ]);
      for (int i = 1; i < ranked.length; i++) {
        expect(ranked[i - 1].score, greaterThanOrEqualTo(ranked[i].score));
      }
    });

    test('two weaker signals together outrank one stronger signal', () {
      final List<DuplicateCandidate> ranked = _rank(
        templateRowId: 'row-1',
        context: north,
        name: 'Pump',
        capturedAt: at,
        perceptualHashes: const <String>{'0000000000000000'},
        others: <DuplicateSubject>[
          const DuplicateSubject(
            recordId: 'near-photo',
            identityHash: 'other',
            perceptualHashes: <String>{'0000000000000000'},
          ),
          DuplicateSubject(
            recordId: 'row-and-name',
            identityHash: 'other',
            templateRowId: 'row-1',
            context: north,
            name: 'Pump',
            capturedAt: at,
          ),
        ],
      );
      expect(ranked.first.recordId, 'row-and-name');
      expect(ranked.first.signals, hasLength(2));
    });

    test('the record itself is never its own candidate', () {
      final List<DuplicateCandidate> ranked = _rank(
        recordId: 'same',
        identity: 'hash-a',
        others: const <DuplicateSubject>[
          DuplicateSubject(recordId: 'same', identityHash: 'hash-a'),
        ],
      );
      expect(ranked, isEmpty);
    });

    test('a record with no signal is left out of the list', () {
      final List<DuplicateCandidate> ranked = _rank(
        identity: 'hash-a',
        others: const <DuplicateSubject>[
          DuplicateSubject(recordId: 'match', identityHash: 'hash-a'),
          DuplicateSubject(recordId: 'stranger', identityHash: 'hash-b'),
        ],
      );
      expect(ranked.map((DuplicateCandidate c) => c.recordId), <String>[
        'match',
      ]);
    });
  });

  test('detection is a proposal: it writes nothing and repeats exactly', () {
    final List<DuplicateSubject> others = <DuplicateSubject>[
      const DuplicateSubject(recordId: 'a', identityHash: 'hash-a'),
      const DuplicateSubject(
        recordId: 'b',
        identityHash: 'other',
        photoHashes: <String>{'sha-1'},
      ),
    ];
    final Set<String> photos = <String>{'sha-1'};
    final List<DuplicateCandidate> first = _rank(
      identity: 'hash-a',
      photoHashes: photos,
      others: others,
    );
    final List<DuplicateCandidate> second = _rank(
      identity: 'hash-a',
      photoHashes: photos,
      others: others,
    );
    expect(others.map((DuplicateSubject s) => s.recordId), <String>['a', 'b']);
    expect(photos, <String>{'sha-1'});
    expect(
      first.map((DuplicateCandidate c) => (c.recordId, c.score, c.signals)),
      second.map((DuplicateCandidate c) => (c.recordId, c.score, c.signals)),
    );
  });
}
