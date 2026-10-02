import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/core/bundle/bundle_password_key_browser_test.dart'
    as protection;

/// Runs the real WebCrypto fixture through the supported browser driver binding.
void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    test('WebCrypto protection requires a browser', () {}, skip: true);
    return;
  }
  protection.main();
  tearDownAll(() {
    binding.reportData = <String, Object?>{'results': binding.results};
    expect(binding.results, hasLength(4));
  });
}
