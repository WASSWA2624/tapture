import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('loading renders the shared skeleton', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AsyncValueView<List<String>>(
        value: const AsyncLoading<List<String>>(),
        data: (_) => const Text('data'),
      ),
    );
    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.text('data'), findsNothing);
  });

  testWidgets('error renders AppErrorState and retry fires', (
    WidgetTester tester,
  ) async {
    var retried = false;
    await _pump(
      tester,
      AsyncValueView<List<String>>(
        value: const AsyncError<List<String>>(
          NetworkFailure(),
          StackTrace.empty,
        ),
        data: (_) => const Text('data'),
        onRetry: () => retried = true,
      ),
    );

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('empty data uses the empty builder, not the data builder', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AsyncValueView<List<String>>(
        value: const AsyncData<List<String>>(<String>[]),
        isEmpty: (List<String> items) => items.isEmpty,
        empty: () => const AppEmptyState(
          icon: Icons.folder_open,
          headline: 'No projects yet',
          message: 'Create a project to start capturing.',
        ),
        data: (_) => const Text('data'),
      ),
    );

    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('data'), findsNothing);
  });

  testWidgets('populated data uses the data builder', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AsyncValueView<List<String>>(
        value: const AsyncData<List<String>>(<String>['Boiler A']),
        isEmpty: (List<String> items) => items.isEmpty,
        empty: () => const AppEmptyState(
          icon: Icons.folder_open,
          headline: 'No projects yet',
          message: 'Create a project to start capturing.',
        ),
        data: (List<String> items) => Text(items.first),
      ),
    );

    expect(find.text('Boiler A'), findsOneWidget);
    expect(find.text('No projects yet'), findsNothing);
  });

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Async',
          body: AsyncValueView<List<String>>(
            value: const AsyncData<List<String>>(<String>[]),
            isEmpty: (List<String> items) => items.isEmpty,
            empty: () => AppEmptyState(
              icon: Icons.folder_open,
              headline: 'No projects yet',
              message: 'Create a project to start capturing.',
              actionLabel: 'Create a project',
              onAction: () {},
            ),
            data: (_) => const Text('data'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

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
