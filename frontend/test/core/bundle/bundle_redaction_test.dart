import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle_redaction.dart';
import 'package:tapture/core/errors/failure.dart';

void main() {
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
