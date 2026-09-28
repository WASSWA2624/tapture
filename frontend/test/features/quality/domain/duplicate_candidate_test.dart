import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/quality/quality.dart';

/// Ranks one probe against one [other] and returns its candidate, or null
/// when no signal fired.
DuplicateCandidate? _candidate({
  String identity = '',
  Set<String> photoHashes = const <String>{},
  Set<String> perceptualHashes = const <String>{},
  String? templateRowId,
  Map<String, String> context = const <String, String>{},
  String name = '',
  DateTime? capturedAt,
  required DuplicateSubject other,
}) {
  final List<DuplicateCandidate> ranked = rankDuplicateCandidates(
    recordId: 'probe',
    identity: identity,
    photoHashes: photoHashes,
    perceptualHashes: perceptualHashes,
    templateRowId: templateRowId,
    context: context,
    name: name,
    capturedAt: capturedAt,
    others: <DuplicateSubject>[other],
  );
  return ranked.isEmpty ? null : ranked.single;
}

void main() {
  final DateTime at = DateTime.utc(2026, 9, 28, 8);

  group('a single signal scores its named weight', () {
    final Map<DuplicateSignal, (DuplicateCandidate?, double)> cases =
        <DuplicateSignal, (DuplicateCandidate?, double)>{
          DuplicateSignal.identity: (
            _candidate(
              identity: 'hash-a',
              other: const DuplicateSubject(
                recordId: 'r',
                identityHash: 'hash-a',
              ),
            ),
            AppConstants.quality.identity,
          ),
          DuplicateSignal.samePhoto: (
            _candidate(
              photoHashes: const <String>{'sha-1'},
              other: const DuplicateSubject(
                recordId: 'r',
                identityHash: 'other',
                photoHashes: <String>{'sha-1'},
              ),
            ),
            AppConstants.quality.samePhoto,
          ),
          DuplicateSignal.nearPhoto: (
            _candidate(
              perceptualHashes: const <String>{'0000000000000000'},
              other: const DuplicateSubject(
                recordId: 'r',
                identityHash: 'other',
                perceptualHashes: <String>{'0000000000000001'},
              ),
            ),
            AppConstants.quality.nearPhoto,
          ),
          DuplicateSignal.predefinedRow: (
            _candidate(
              templateRowId: 'row-1',
              context: const <String, String>{'site': 'North'},
              other: const DuplicateSubject(
                recordId: 'r',
                identityHash: 'other',
                templateRowId: 'row-1',
                context: <String, String>{'site': 'North'},
              ),
            ),
            AppConstants.quality.predefinedRow,
          ),
          DuplicateSignal.nameContextTime: (
            _candidate(
              name: 'Pump',
              context: const <String, String>{'site': 'North'},
              capturedAt: at,
              other: DuplicateSubject(
                recordId: 'r',
                identityHash: 'other',
                name: 'Pump',
                context: const <String, String>{'site': 'North'},
                capturedAt: at,
              ),
            ),
            AppConstants.quality.nameContext,
          ),
        };

    for (final MapEntry<DuplicateSignal, (DuplicateCandidate?, double)> entry
        in cases.entries) {
      test('${entry.key.name} alone scores its weight', () {
        final DuplicateCandidate? candidate = entry.value.$1;
        expect(candidate, isNotNull);
        expect(candidate!.recordId, 'r');
        expect(candidate.signals, <DuplicateSignal>{entry.key});
        expect(candidate.score, closeTo(entry.value.$2, 1e-9));
      });
    }
  });

  test('a score never leaves the 0 to 1 range, even with every signal', () {
    final DuplicateCandidate? candidate = _candidate(
      identity: 'hash-a',
      photoHashes: const <String>{'sha-1'},
      perceptualHashes: const <String>{'0000000000000000'},
      templateRowId: 'row-1',
      context: const <String, String>{'site': 'North'},
      name: 'Pump',
      capturedAt: at,
      other: DuplicateSubject(
        recordId: 'r',
        identityHash: 'hash-a',
        photoHashes: const <String>{'sha-1'},
        perceptualHashes: const <String>{'0000000000000000'},
        templateRowId: 'row-1',
        context: const <String, String>{'site': 'North'},
        name: 'Pump',
        capturedAt: at,
      ),
    );
    expect(candidate, isNotNull);
    expect(
      candidate!.signals,
      DuplicateSignal.values.toSet().difference(<DuplicateSignal>{
        DuplicateSignal.photo,
        DuplicateSignal.caption,
      }),
    );
    expect(candidate.score, inInclusiveRange(0, 1));
    expect(
      candidate.score,
      greaterThanOrEqualTo(AppConstants.quality.identity),
    );
  });

  test('more signals score higher than a subset of them', () {
    final DuplicateCandidate? one = _candidate(
      photoHashes: const <String>{'sha-1'},
      other: const DuplicateSubject(
        recordId: 'r',
        identityHash: 'other',
        photoHashes: <String>{'sha-1'},
      ),
    );
    final DuplicateCandidate? two = _candidate(
      photoHashes: const <String>{'sha-1'},
      templateRowId: 'row-1',
      other: const DuplicateSubject(
        recordId: 'r',
        identityHash: 'other',
        photoHashes: <String>{'sha-1'},
        templateRowId: 'row-1',
      ),
    );
    expect(two!.score, greaterThan(one!.score));
    expect(two.signals, containsAll(one.signals));
  });

  test('a candidate carries only the signals that fired', () {
    final DuplicateCandidate? candidate = _candidate(
      identity: 'hash-a',
      photoHashes: const <String>{'sha-1'},
      perceptualHashes: const <String>{'0000000000000000'},
      other: const DuplicateSubject(
        recordId: 'r',
        identityHash: 'hash-a',
        photoHashes: <String>{'sha-2'},
        perceptualHashes: <String>{'ffffffffffffffff'},
      ),
    );
    expect(candidate!.signals, <DuplicateSignal>{DuplicateSignal.identity});
  });

  test('each candidate in one ranking holds its own signals', () {
    final List<DuplicateCandidate> ranked = rankDuplicateCandidates(
      recordId: 'probe',
      identity: 'hash-a',
      photoHashes: const <String>{'sha-1'},
      perceptualHashes: const <String>{},
      templateRowId: null,
      context: const <String, String>{},
      name: '',
      capturedAt: null,
      others: const <DuplicateSubject>[
        DuplicateSubject(recordId: 'by-identity', identityHash: 'hash-a'),
        DuplicateSubject(
          recordId: 'by-photo',
          identityHash: 'other',
          photoHashes: <String>{'sha-1'},
        ),
      ],
    );
    final DuplicateCandidate byIdentity = ranked.firstWhere(
      (DuplicateCandidate c) => c.recordId == 'by-identity',
    );
    final DuplicateCandidate byPhoto = ranked.firstWhere(
      (DuplicateCandidate c) => c.recordId == 'by-photo',
    );
    expect(byIdentity.signals, <DuplicateSignal>{DuplicateSignal.identity});
    expect(byPhoto.signals, <DuplicateSignal>{DuplicateSignal.samePhoto});
  });
}
