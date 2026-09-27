import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle_encryption.dart';
import 'package:tapture/core/errors/failure.dart';

void main() {
  test(
    'the right password opens the bundle and the wrong one writes nothing',
    () {
      final BundleEncryption encryption = BundleEncryption();
      final Uint8List plain = Uint8List.fromList(utf8.encode('project rows'));
      final Uint8List sealed = encryption.seal(plain, 'correct');
      expect(encryption.open(sealed, 'correct'), plain);
      expect(
        () => encryption.open(sealed, 'wrong'),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );
}
