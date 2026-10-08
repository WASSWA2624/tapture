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

import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('numbered pinned rows at 400 dp, default and 200 percent text', (
    WidgetTester tester,
  ) async {
    final List<String> failures = <String>[];
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    for (final String name in <String>['Alpha', 'Beta']) {
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
    _ok(await repo.setPinned('project-Beta', true));
    for (final AppThemeMode mode in <AppThemeMode>[
      AppThemeMode.light,
      AppThemeMode.dark,
      AppThemeMode.outdoor,
    ]) {
      for (final double scale in <double>[1, 2]) {
        await _pumpList(tester, mode: mode, repo: repo, textScale: scale);
        final String suffix = scale == 2 ? '_text2' : '';
        try {
          await expectLater(
            find.byKey(const ValueKey<String>('route-projects')),
            matchesGoldenFile(
              'goldens/project_list_numbered_pinned${suffix}_${mode.name}.png',
            ),
          );
        } catch (error) {
          failures.add('list ${mode.name} scale $scale: $error');
        }
      }
    }
    if (failures.isNotEmpty) {
      fail('golden moved:\n${failures.join('\n')} (FE-TEST-02)');
    }
  });
}

Future<void> _pumpList(
  WidgetTester tester, {
  required AppThemeMode mode,
  required FakeProjectRepository repo,
  required double textScale,
}) async {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
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
