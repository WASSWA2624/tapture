import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/validation/field_rule.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/import/presentation/record_mapping_screen.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'The sheet could not be read.',
    recoveryAction: 'Try again.',
  );
  const FieldRule serial = FieldRule(
    fieldKey: 'serial',
    label: 'Serial',
    identity: true,
  );

  testWidgets('a preselected mapping continues and a missing identity blocks', (
    WidgetTester tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RecordMappingScreen(
          headers: const <String>['Serial'],
          fields: const <FieldRule>[serial],
          columnToField: const <String, String>{'Serial': 'serial'},
          preview: const <Map<String, String>>[
            <String, String>{'serial': 'A-1'},
          ],
          onContinue: () => continued = true,
        ),
      ),
    );
    expect(find.text('A-1'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('import-mapping-continue')),
    );
    await tester.pump();
    expect(continued, isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: RecordMappingScreen(
          headers: <String>['Notes'],
          fields: <FieldRule>[serial],
        ),
      ),
    );
    expect(find.text(Copy.importIdentityMissing('Serial')), findsOneWidget);
  });

  testWidgets('empty, loading and failure', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RecordMappingScreen()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: RecordMappingScreen(loading: true)),
    );
    expect(find.byType(AppEmptyState), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: RecordMappingScreen(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
