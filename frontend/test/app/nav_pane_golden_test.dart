import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/features/projects/projects.dart';

import '../features/projects/fakes/fake_project_repository.dart';
import '../support/factories.dart';

const ValueKey<String> _paneKey = ValueKey<String>('nav-pane');

void main() {
  testWidgets('pane goldens at 1200 dp, empty and with three projects', (
    WidgetTester tester,
  ) async {
    final List<String> failures = <String>[];
    for (final AppThemeMode mode in <AppThemeMode>[
      AppThemeMode.light,
      AppThemeMode.dark,
      AppThemeMode.outdoor,
    ]) {
      await _pumpPane(tester, mode: mode);
      try {
        await expectLater(
          find.byKey(_paneKey),
          matchesGoldenFile('goldens/nav_pane_empty_${mode.name}.png'),
        );
      } catch (error) {
        failures.add('empty ${mode.name}: $error');
      }

      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      for (final String name in <String>['Alpha', 'Beta', 'Gamma']) {
        _ok(
          await repo.create(
            aProject(
              id: 'project-$name',
              name: name,
              updatedAt: DateTime.utc(2026, 9, 17, 8),
            ),
          ),
        );
      }
      await _pumpPane(tester, mode: mode, repo: repo);
      try {
        await expectLater(
          find.byKey(_paneKey),
          matchesGoldenFile('goldens/nav_pane_projects_${mode.name}.png'),
        );
      } catch (error) {
        failures.add('projects ${mode.name}: $error');
      }
    }
    if (failures.isNotEmpty) {
      fail('golden moved:\n${failures.join('\n')} (FE-TEST-02)');
    }
  });
}

Future<void> _pumpPane(
  WidgetTester tester, {
  required AppThemeMode mode,
  FakeProjectRepository? repo,
}) async {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 800);
  tester.platformDispatcher.textScaleFactorTestValue = 1;
  tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(() {
    debugDisableShadows = false;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[
        networkOnlineOverride(),
        themeModeProvider.overrideWith(
          () => ThemeModeController.withStore(
            TextStore.memory(<String, String>{
              AppConstants.preferences.themeMode: mode.name,
            }),
          ),
        ),
        if (repo != null)
          projectRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: const TaptureApp(),
    ),
  );
  await tester.pumpAndSettle();
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
