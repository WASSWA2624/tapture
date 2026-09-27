import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/validation/validation.dart';
import 'package:tapture/core/widgets/forms/validation_display.dart';

import '../../../design_system/golden_harness.dart';

void main() {
  testWidgets('validation summary in light, dark and outdoor', (
    WidgetTester tester,
  ) async {
    await expectGolden(
      tester,
      const ValidationDisplay.summary(
        issues: <ValidationIssue>[
          ValidationIssue('serial', Severity.error, 'Serial is required.'),
          ValidationIssue('note', Severity.warning, 'Note is required.'),
        ],
      ),
      'validation_display',
    );
  });
}
