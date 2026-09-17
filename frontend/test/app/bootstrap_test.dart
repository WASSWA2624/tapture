import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/main.dart' as app;

void main() {
  setUp(app.debugBootstrapErrors.clear);

  testWidgets('an uncaught error is captured and the app still renders', (
    WidgetTester tester,
  ) async {
    await app.main();
    await tester.pump();

    final StateError error = StateError('bootstrap');
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: StackTrace.current),
    );

    expect(app.debugBootstrapErrors, contains(error));
    expect(tester.takeException(), same(error));
    expect(find.byType(TaptureApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
