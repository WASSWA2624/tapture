import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/feedback/app_panel_dialog.dart';
import 'package:tapture/features/feedback/presentation/open_feedback_flow.dart';

void main() {
  testWidgets('a desktop with room still opens a screen, not a dialog', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(
          brightness: Brightness.light,
        ).copyWith(platform: TargetPlatform.windows),
        home: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () {
                unawaited(
                  openFeedbackFlow<void>(
                    context,
                    page: const Scaffold(body: Text('Give screen')),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Give screen'), findsOneWidget);
    expect(find.byType(AppPanelDialog), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });
}
