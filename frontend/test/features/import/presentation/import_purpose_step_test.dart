import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/import/presentation/import_purpose_step.dart';
import 'package:tapture/features/quality/quality.dart' show VerificationPrefill;

void main() {
  const Failure failed = StorageFailure(
    message: 'The sheet could not be read.',
    recoveryAction: 'Choose another file.',
  );

  testWidgets('records and a register are both offered', (
    WidgetTester tester,
  ) async {
    var records = false;
    List<VerificationPrefill>? register;
    await tester.pumpWidget(
      MaterialApp(
        home: ImportPurposeStep(
          rows: const <Map<String, String>>[
            <String, String>{'Serial': 'A-1'},
          ],
          binding: const <String, String>{'serial': 'Serial'},
          onRecords: () => records = true,
          onRegister: (List<VerificationPrefill> filled) => register = filled,
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('import-purpose-records')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('import-purpose-register')),
    );
    await tester.pump();
    expect(records, isTrue);
    expect(register, isNotNull);
    expect(register!.single.asRecorded['serial'], 'A-1');
    expect(register!.single.onRegister, isTrue);
  });

  testWidgets('empty, loading and failure', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ImportPurposeStep(empty: true)),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ImportPurposeStep(loading: true)),
    );
    expect(find.byType(AppEmptyState), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: ImportPurposeStep(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
