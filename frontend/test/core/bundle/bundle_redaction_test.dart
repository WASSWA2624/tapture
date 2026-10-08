import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle_redaction.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

void main() {
  test('nested DEFLATE dictionary copies stop at the declared entry bound', () {
    final Uint8List bytes = ZipEncoder().encodeBytes(
      Archive()..addFile(
        ArchiveFile.bytes('payload.txt', List<int>.filled(100000, 32)),
      ),
    );
    final ByteData header = ByteData.sublistView(bytes);
    final int directory = List<int>.generate(bytes.length - 4, (index) => index)
        .firstWhere(
          (index) => header.getUint32(index, Endian.little) == 0x02014b50,
        );
    // Consistent ZIP metadata must not let a tiny claim hide expanded output.
    header.setUint32(22, 8, Endian.little);
    header.setUint32(directory + 24, 8, Endian.little);
    final BundleRedaction redaction = BundleRedaction.parse(
      File('tool/secret_patterns.yaml').readAsStringSync(),
    );
    expect(
      () => redaction.assertCleanPayload(bytes),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.explanation,
          'declared output bound',
          Copy.messages.failureANestedBundleEntryExceedsItsDeclared,
        ),
      ),
    );
  });

  test(
    'secret key aliases are stripped from nested settings without changing the source',
    () {
      final Map<String, Object?> source = <String, Object?>{
        'name': 'Pump',
        'apiKey': 'unshaped confidential value',
        'settings': jsonEncode(<String, Object?>{
          'label': 'Team',
          'Access-Token': 'short',
          'provider': <String, Object?>{
            'clientSecret': 'short',
            'model': 'local',
          },
          'items': <Object?>[
            <String, Object?>{'deviceSecret': 'private', 'label': 'a'},
          ],
        }),
      };
      final String original = jsonEncode(source);
      final Map<String, Object?> safe = BundleRedaction.redact(source);
      expect(safe.containsKey('apiKey'), isFalse);
      expect(jsonDecode(safe['settings']! as String), <String, Object?>{
        'label': 'Team',
        'provider': <String, Object?>{'model': 'local'},
        'items': <Object?>[
          <String, Object?>{'label': 'a'},
        ],
      });
      expect(jsonEncode(source), original);
    },
  );
  test(
    'a secret-shaped value fails the write and secret columns are dropped',
    () {
      final String yaml = File('tool/secret_patterns.yaml').readAsStringSync();
      final BundleRedaction redaction = BundleRedaction.parse(yaml);
      final Map<String, Object?> row = redaction.strip(<String, Object?>{
        'name': 'Pump',
        'password': 'hidden',
      });
      expect(row.containsKey('password'), isFalse);
      expect(row['name'], 'Pump');
      expect(
        () => redaction.assertClean('sk-abcdefghijklmnopqrstuvwxyz'),
        throwsA(isA<ValidationFailure>()),
      );
      redaction.assertClean('a pump serial');
    },
  );
}
