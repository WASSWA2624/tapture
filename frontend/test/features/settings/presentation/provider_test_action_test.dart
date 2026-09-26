import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/settings/presentation/provider_test_action.dart';

void main() {
  Future<void> pump(WidgetTester tester, ProviderTestAction action) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(body: action),
      ),
    );
  }

  testWidgets('with nothing to test it explains custody', (
    WidgetTester tester,
  ) async {
    await pump(tester, const ProviderTestAction());

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.apiKeyCustody), findsOneWidget);
  });

  testWidgets('a failure to load shows the error and retries the test', (
    WidgetTester tester,
  ) async {
    var tests = 0;
    await pump(
      tester,
      ProviderTestAction(
        failure: const NetworkFailure(),
        onTest: () => tests++,
      ),
    );

    expect(find.byType(AppErrorState), findsOneWidget);
    await tester.tap(find.text(Copy.tryAgain));
    await tester.pump();
    expect(tests, 1);
  });

  testWidgets('authentication and network failures read differently', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      ProviderTestAction(view: ProviderTestView.authentication, onTest: () {}),
    );
    expect(find.text(Copy.apiKeyAuthFailed), findsOneWidget);
    expect(find.text(Copy.apiKeyNetworkFailed), findsNothing);

    await pump(
      tester,
      ProviderTestAction(view: ProviderTestView.network, onTest: () {}),
    );
    expect(find.text(Copy.apiKeyNetworkFailed), findsOneWidget);
    expect(find.text(Copy.apiKeyAuthFailed), findsNothing);
    expect(Copy.apiKeyAuthFailed, isNot(Copy.apiKeyNetworkFailed));
  });

  testWidgets('every outcome has its own message', (WidgetTester tester) async {
    final Map<ProviderTestView, String> messages = <ProviderTestView, String>{
      ProviderTestView.success: Copy.apiKeySuccess,
      ProviderTestView.authentication: Copy.apiKeyAuthFailed,
      ProviderTestView.network: Copy.apiKeyNetworkFailed,
      ProviderTestView.unavailable: Copy.aiProviderUnavailable,
      ProviderTestView.validation: Copy.aiSelectionInvalid,
      ProviderTestView.failed: Copy.apiKeyTestFailed,
    };
    for (final MapEntry<ProviderTestView, String> entry in messages.entries) {
      await pump(tester, ProviderTestAction(view: entry.key, onTest: () {}));
      expect(find.text(entry.value), findsOneWidget, reason: entry.key.name);
    }
    expect(messages.values.toSet(), hasLength(messages.length));
  });

  testWidgets('the test button runs the test', (WidgetTester tester) async {
    var tests = 0;
    await pump(tester, ProviderTestAction(onTest: () => tests++));

    await tester.tap(find.text(Copy.apiKeyTest));
    await tester.pump();

    expect(tests, 1);
  });
}
