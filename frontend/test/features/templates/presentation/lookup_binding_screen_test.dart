import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/reference/domain/lookup_binding.dart';
import 'package:tapture/features/templates/presentation/lookup_binding_screen.dart';

void main() {
  testWidgets('lookup_binding_screen failure state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LookupBindingScreen(
            templateId: 't1',
            fieldKey: 'supplier',
            failure: StorageFailure(
              message: 'bind-fail',
              recoveryAction: 'retry',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('bind-fail'), findsWidgets);
  });

  test('rejects unknown and duplicate fill targets', () {
    expect(
      LookupBinding.validate(
        binding: const LookupBinding(
          datasetId: 'ds',
          matchColumns: <String>['code'],
          fillMapping: <String, String>{'name': 'missing'},
        ),
        templateFieldKeys: const <String>{'phone'},
      ),
      contains('Unknown'),
    );
    expect(
      LookupBinding.validate(
        binding: const LookupBinding(
          datasetId: 'ds',
          matchColumns: <String>['code'],
          fillMapping: <String, String>{'name': 'phone', 'code': 'phone'},
        ),
        templateFieldKeys: const <String>{'phone'},
      ),
      contains('more than once'),
    );
  });

  testWidgets('lookup_binding_screen empty datasets path uses copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[],
        child: const MaterialApp(
          home: LookupBindingScreen(templateId: 'missing', fieldKey: 'x'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Empty template → templates empty or datasets empty copy.
    expect(
      find.text(Copy.templatesEmptyHeadline).evaluate().isNotEmpty ||
          find.text(Copy.datasetsBindingEmptyHeadline).evaluate().isNotEmpty ||
          find.text(Copy.datasetsBrowserEmptyHeadline).evaluate().isNotEmpty,
      isTrue,
    );
  });
}
