@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/app/navigation_browser_test.dart' as suite;

/// Runs the shared production-router checks in the browser integration runner.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  suite.main();
}
