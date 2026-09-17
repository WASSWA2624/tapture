import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/error_boundary.dart';

void main() {
  testWidgets(
    'a throwing child shows a recoverable panel and retry rebuilds it',
    (WidgetTester tester) async {
      var shouldThrow = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            onRetry: () => shouldThrow = false,
            child: Builder(
              builder: (BuildContext _) {
                if (shouldThrow) {
                  throw StateError('boom');
                }
                return const Text('recovered');
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<StateError>());
      expect(find.text('recovered'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
      expect(
        find.text('Try again. Nothing already captured was lost.'),
        findsOneWidget,
      );
      expect(find.byType(ErrorWidget), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(find.text('recovered'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    },
  );
}
