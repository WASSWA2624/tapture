import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/features/settings/presentation/provider_test_action.dart';

void main() {
  testWidgets(
    'connection testing is secondary and starts only on an explicit action',
    (WidgetTester tester) async {
      int requests = 0;
      await _pump(tester, onTest: () => requests++);
      expect(requests, 0);
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).variant,
        AppButtonVariant.secondary,
      );
      expect(
        tester.getSize(find.byType(AppButton)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text(Copy.apiKeyTest));
      await tester.pumpAndSettle();
      expect(requests, 1);
    },
  );

  for (final ProviderTestView outcome in ProviderTestView.values.where(
    (value) => value != ProviderTestView.empty,
  )) {
    testWidgets(
      '${outcome.name} reports the outcome without starting another request',
      (WidgetTester tester) async {
        int requests = 0;
        await _pump(tester, view: outcome, onTest: () => requests++);
        expect(requests, 0);
        expect(find.byType(AppBanner), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('provider-test-outcome')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unavailable provider has no enabled connection action', (
    WidgetTester tester,
  ) async {
    await _pump(tester, view: ProviderTestView.unavailable);
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    expect(find.text(Copy.aiProviderUnavailable), findsOneWidget);
  });

  testWidgets('the explicit action and outcome can be placed independently', (
    WidgetTester tester,
  ) async {
    int requests = 0;
    await _pump(
      tester,
      view: ProviderTestView.success,
      onTest: () => requests++,
      showAction: false,
    );
    expect(find.byType(AppButton), findsNothing);
    expect(find.text(Copy.apiKeySuccess), findsOneWidget);
    await _pump(
      tester,
      view: ProviderTestView.success,
      onTest: () => requests++,
      showOutcome: false,
    );
    expect(find.byType(AppButton), findsOneWidget);
    expect(find.text(Copy.apiKeySuccess), findsNothing);
    await tester.tap(find.text(Copy.apiKeyTest));
    await tester.pumpAndSettle();
    expect(requests, 1);
    await _pump(tester, showAction: false, showOutcome: false);
    expect(find.text(Copy.apiKeyTest), findsNothing);
    expect(find.text(Copy.apiKeyCustody), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ProviderTestView view = ProviderTestView.empty,
  VoidCallback? onTest,
  bool showAction = true,
  bool showOutcome = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: ProviderTestAction(
          view: view,
          onTest: onTest,
          showAction: showAction,
          showOutcome: showOutcome,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
