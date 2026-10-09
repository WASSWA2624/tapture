@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';

import 'capture_field_sources_fixture.dart';

void main() => registerCaptureSourceTests(browser: true);
