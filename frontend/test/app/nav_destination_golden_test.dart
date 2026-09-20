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

void main() {
  testWidgets(
    'bar and rail goldens at 200 percent text with two- and three-digit counts',
    (WidgetTester tester) async {
      final List<String> failures = <String>[];
      final FakeProjectRepository twelve = await _seed(12);
      addTearDown(twelve.dispose);
      final FakeProjectRepository hundred = await _seed(100);
      addTearDown(hundred.dispose);
      for (final AppThemeMode mode in <AppThemeMode>[
        AppThemeMode.light,
        AppThemeMode.dark,
        AppThemeMode.outdoor,
      ]) {
        for (final ({
              String chrome,
              Size size,
              String count,
              FakeProjectRepository repo,
            })
            shot
            in <
              ({
                String chrome,
                Size size,
                String count,
                FakeProjectRepository repo,
              })
            >[
              (
                chrome: 'nav-bar',
                size: const Size(400, 800),
                count: '12',
                repo: twelve,
              ),
              (
                chrome: 'nav-bar',
                size: const Size(400, 800),
                count: '100',
                repo: hundred,
              ),
              (
                chrome: 'nav-rail',
                size: const Size(800, 800),
                count: '12',
                repo: twelve,
              ),
              (
                chrome: 'nav-rail',
                size: const Size(800, 800),
                count: '100',
                repo: hundred,
              ),
            ]) {
          await _pump(tester, size: shot.size, mode: mode, repo: shot.repo);
          try {
            await expectLater(
              find.byKey(ValueKey<String>(shot.chrome)),
              matchesGoldenFile(
                'goldens/nav_${shot.chrome == 'nav-bar' ? 'bar' : 'rail'}'
                '_count_${shot.count}_${mode.name}.png',
              ),
            );
          } catch (error) {
            failures.add('${shot.chrome} ${shot.count} ${mode.name}: $error');
          }
        }
      }
      if (failures.isNotEmpty) {
        fail('golden moved:\n${failures.join('\n')} (FE-TEST-02)');
      }
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required AppThemeMode mode,
  required FakeProjectRepository repo,
}) async {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
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

Future<FakeProjectRepository> _seed(int count) async {
  final FakeProjectRepository repo = FakeProjectRepository();
  for (int index = 0; index < count; index++) {
    _ok(
      await repo.create(
        aProject(
          id: 'project-$index',
          name: 'Project $index',
          updatedAt: DateTime.utc(2026, 9, 17, 8),
        ),
      ),
    );
  }
  return repo;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
