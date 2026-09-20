import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/templates/presentation/field_options_editor.dart';

void main() {
  test('rename updates the label and leaves the stored code', () {
    final Object option = FieldOptionsEditor.encode((
      code: 'open',
      label: 'Open',
      retired: false,
    ));
    final Object renamed = FieldOptionsEditor.rename(option, 'Opened');
    expect(FieldOptionsEditor.decode(renamed).code, 'open');
    expect(FieldOptionsEditor.decode(renamed).label, 'Opened');
    expect(FieldOptionsEditor.decode(renamed).retired, isFalse);

    final Object retired = FieldOptionsEditor.retire(option);
    expect(FieldOptionsEditor.decode(retired).code, 'open');
    expect(FieldOptionsEditor.decode(retired).retired, isTrue);
    expect(
      FieldOptionsEditor.codeFrom('Open', const <String>['open']),
      'open_2',
    );
  });

  testWidgets('an empty choice list renders the empty panel', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const FieldOptionsEditor(options: <Object>[], onChanged: _ignore),
    );

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.fieldOptionsEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.fieldOptionsEmptyMessage), findsOneWidget);
  });

  testWidgets('a known failure renders through AppErrorState', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const FieldOptionsEditor(
        options: <Object>[],
        onChanged: _ignore,
        failure: StorageFailure(
          message: 'The choices could not be saved.',
          recoveryAction: 'Try again.',
        ),
      ),
    );

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The choices could not be saved.'), findsOneWidget);
  });

  testWidgets('a blank add writes nothing', (WidgetTester tester) async {
    List<Object> latest = const <Object>[];
    await _pump(
      tester,
      FieldOptionsEditor(
        options: const <Object>[],
        onChanged: (List<Object> next) => latest = next,
      ),
    );

    await tester.tap(find.text(Copy.fieldOptionAdd));
    await tester.pump();

    expect(latest, isEmpty);
    expect(find.text(Copy.fieldOptionsEmptyHeadline), findsOneWidget);
  });
}

void _ignore(List<Object> _) {}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}
