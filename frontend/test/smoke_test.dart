import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/main.dart' as app;

void main() {
  testWidgets('the app builds an empty scaffold without throwing', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });
}
