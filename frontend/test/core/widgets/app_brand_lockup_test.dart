import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_brand_lockup.dart';

void main() {
  testWidgets('the lockup shows the mark and the product name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const Scaffold(body: AppBrandLockup()),
      ),
    );

    expect(find.text(Copy.appName), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
