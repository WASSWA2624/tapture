import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/templates/presentation/field_validation_editor.dart';
import 'package:tapture/features/templates/templates.dart';

void main() {
  test('testValue runs the registry against a sample', () {
    const Map<String, Object?> serial = <String, Object?>{
      'pattern': r'^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$',
    };
    expect(
      FieldValidationEditor.testValue(
        type: FieldType.text,
        validation: serial,
        sample: 'A-1',
      ),
      isA<Success<void>>(),
    );
    expect(
      FieldValidationEditor.testValue(
        type: FieldType.text,
        validation: serial,
        sample: 'A 1',
      ),
      isA<FailureResult<void>>(),
    );
    expect(
      FieldValidationEditor.testValue(
        type: FieldType.text,
        validation: const <String, Object?>{'pattern': '('},
        sample: 'A',
      ),
      isA<FailureResult<void>>(),
    );
    expect(FieldValidationEditor.readyMade.keys, <String>{
      'serial',
      'asset_tag',
      'registration',
    });
  });

  testWidgets('an empty rule list renders the empty panel', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const FieldValidationEditor(
        validation: <String, Object?>{},
        type: FieldType.text,
        onChanged: _ignore,
      ),
    );

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.fieldValidationEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.fieldValidationEmptyMessage), findsOneWidget);
  });

  testWidgets('a known failure renders through AppErrorState', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const FieldValidationEditor(
        validation: <String, Object?>{},
        type: FieldType.text,
        onChanged: _ignore,
        failure: StorageFailure(
          message: 'The rule could not be checked.',
          recoveryAction: 'Try again.',
        ),
      ),
    );

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The rule could not be checked.'), findsOneWidget);
  });

  testWidgets('a sample can be tested before save', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const FieldValidationEditor(
        validation: <String, Object?>{'minLength': 5},
        type: FieldType.text,
        onChanged: _ignore,
      ),
    );

    await tester.enterText(find.byType(TextField).last, 'ab');
    await tester.pump();

    expect(
      find.text('That value is shorter than this field allows.'),
      findsWidgets,
    );

    await tester.enterText(find.byType(TextField).last, 'abcde');
    await tester.pump();

    expect(find.text(Copy.fieldPatternTestPass), findsOneWidget);
  });
}

void _ignore(Map<String, Object?> _) {}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}
