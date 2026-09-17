import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  for (final Failure failure in _failures) {
    testWidgets('${failure.runtimeType} shows its message and retry fires', (
      WidgetTester tester,
    ) async {
      var retried = false;
      await _pump(
        tester,
        AppErrorState(failure: failure, onRetry: () => retried = true),
      );

      expect(find.text(failure.message), findsOneWidget);
      final String? recovery = failure.recoveryAction;
      if (recovery != null) {
        expect(find.text(recovery), findsOneWidget);
      }
      expect(find.byType(AppButton), meetsTapTarget());

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retried, isTrue);
    });
  }

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppPage(
          title: 'Error',
          body: AppErrorState(failure: NetworkFailure(), onRetry: _ignore),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

const List<Failure> _failures = <Failure>[
  NetworkFailure(),
  PermissionFailure(),
  StorageFailure(),
  ValidationFailure(),
  CorruptionFailure(),
  CancelledFailure(),
  ProviderFailure(),
];

void _ignore() {}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}
