import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_matchers.dart';

void main() {
  group('hasSemanticLabel', () {
    testWidgets('a button that names itself passes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(ElevatedButton(onPressed: () {}, child: const Text('Save'))),
      );

      expect(find.byType(ElevatedButton), hasSemanticLabel('Save'));
    });

    testWidgets(
      'a button without a semantic label fails with a readable message',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _app(IconButton(onPressed: () {}, icon: const Icon(Icons.close))),
        );

        late String message;
        try {
          expect(find.byType(IconButton), hasSemanticLabel('Close'));
        } on TestFailure catch (failure) {
          message = failure.message ?? '';
        }

        expect(message, contains('IconButton'));
        expect(message, contains('Close'));
        expect(message, contains('FE-A11Y-02'));
      },
    );
  });

  group('meetsTapTarget', () {
    testWidgets('a 48dp icon button passes', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          IconButton(
            onPressed: () {},
            tooltip: 'Save',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: const Icon(Icons.save),
          ),
        ),
      );

      expect(find.byType(IconButton), meetsTapTarget());
    });

    testWidgets('a 40dp icon button fails, naming the widget and the size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          IconButton(
            onPressed: () {},
            tooltip: 'Close',
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              maximumSize: const Size(40, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.close, size: 20),
          ),
        ),
      );

      late String message;
      try {
        expect(find.byType(IconButton), meetsTapTarget());
      } on TestFailure catch (failure) {
        message = failure.message ?? '';
      }

      expect(message, contains('IconButton'));
      expect(message, contains('40'));
      expect(message, contains('48'));
      expect(message, contains('FE-A11Y-01'));
    });
  });

  group('expectNoA11yIssues', () {
    testWidgets('a labelled 48dp button passes', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(ElevatedButton(onPressed: () {}, child: const Text('Save'))),
      );

      await expectNoA11yIssues(tester);
    });

    testWidgets('a widget that breaks the framework guidelines fails', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(IconButton(onPressed: () {}, icon: const Icon(Icons.close))),
      );

      late String message;
      try {
        await expectNoA11yIssues(tester);
      } on TestFailure catch (failure) {
        message = failure.message ?? '';
      }

      expect(message, contains('accessibility issues'));
      expect(message, isNot(isEmpty));
    });

    testWidgets('a tree that clips at 200 percent text scale fails', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Row(
            children: <Widget>[
              Text('A long label that needs the whole row at normal scale'),
              Text('and a second label that cannot shrink'),
            ],
          ),
        ),
      );

      late String message;
      try {
        await expectNoA11yIssues(tester);
      } on TestFailure catch (failure) {
        message = failure.message ?? '';
      }

      expect(message, contains('200 percent'));
      expect(message, contains('FE-A11Y-03'));
    });
  });
}

/// A one-child Material app so buttons have a theme and a direction.
Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}
