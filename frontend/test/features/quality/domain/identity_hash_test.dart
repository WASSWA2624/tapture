import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  const List<String> keys = <String>['serial'];

  test('identity hashes ignore spacing, case and punctuation', () {
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

  group('normaliseIdentity', () {
    const Map<String, String> cases = <String, String>{
      'ABB-1234': 'abb1234',
      'abb 1234': 'abb1234',
      ' Abb_12.34 ': 'abb1234',
      'A.B.B./12/34': 'abb1234',
      'Café-01': 'cafe01',
      'SN 458923': 'sn458923',
      '': '',
      '---': '',
    };
    for (final MapEntry<String, String> entry in cases.entries) {
      test('"${entry.key}" folds to "${entry.value}"', () {
        expect(normaliseIdentity(entry.key), entry.value);
      });
    }
  });

  test('the hash is stable across calls', () {
    final String first = identityHash(
      const <String, Object?>{'serial': 'ABB-1234', 'tag': 'T-9'},
      const <String>['serial', 'tag'],
    );
    final String second = identityHash(
      const <String, Object?>{'serial': 'ABB-1234', 'tag': 'T-9'},
      const <String>['serial', 'tag'],
    );
    expect(first, second);
    expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('the order of the identity keys does not change the hash', () {
    const Map<String, Object?> values = <String, Object?>{
      'serial': 'ABB-1234',
      'tag': 'T-9',
    };
    expect(
      identityHash(values, const <String>['serial', 'tag']),
      identityHash(values, const <String>['tag', 'serial']),
    );
  });

  test('a missing identity value hashes as an empty one', () {
    expect(
      identityHash(
        const <String, Object?>{'serial': 'ABB-1234'},
        const <String>['serial', 'tag'],
      ),
      identityHash(
        const <String, Object?>{'serial': 'ABB-1234', 'tag': ''},
        const <String>['serial', 'tag'],
      ),
    );
    expect(
      identityHash(
        const <String, Object?>{'serial': 'ABB-1234'},
        const <String>['serial', 'tag'],
      ),
      identityHash(
        const <String, Object?>{'serial': 'ABB-1234', 'tag': null},
        const <String>['serial', 'tag'],
      ),
    );
  });

  test('fields outside the identity never move the hash', () {
    expect(
      identityHash(const <String, Object?>{
        'serial': 'ABB-1234',
        'note': 'Worn',
      }, keys),
      identityHash(const <String, Object?>{
        'serial': 'ABB-1234',
        'note': 'New',
      }, keys),
    );
  });

  test('editing an identity value gives a new hash', () {
    final String before = identityHash(const <String, Object?>{
      'serial': 'ABB-1234',
    }, keys);
    final String after = identityHash(const <String, Object?>{
      'serial': 'ABB-1234-B',
    }, keys);
    expect(after, isNot(before));
  });

  test('a non-text identity value hashes by its text form', () {
    expect(
      identityHash(const <String, Object?>{'serial': 1234}, keys),
      identityHash(const <String, Object?>{'serial': '1234'}, keys),
    );
  });

  test('two identity fields do not collide with one that joins them', () {
    expect(
      identityHash(
        const <String, Object?>{'serial': 'ABB', 'tag': '1234'},
        const <String>['serial', 'tag'],
      ),
      isNot(identityHash(const <String, Object?>{'serial': 'ABB1234'}, keys)),
    );
  });
}
