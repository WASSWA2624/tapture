import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/features/projects/presentation/project_home_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('Open with on the project row menu at 400 dp', (
    WidgetTester tester,
  ) async {
    await _goldens(tester, surface: _Surface.list);
  });

  testWidgets('Open with on the project home menu at 400 dp', (
    WidgetTester tester,
  ) async {
    await _goldens(tester, surface: _Surface.home);
  });
}

Future<void> _goldens(WidgetTester tester, {required _Surface surface}) async {
  final List<String> failures = <String>[];
  for (final AppThemeMode mode in <AppThemeMode>[
    AppThemeMode.light,
    AppThemeMode.dark,
    AppThemeMode.outdoor,
  ]) {
    for (final double scale in <double>[1, 2]) {
      await _pump(tester, surface: surface, mode: mode, textScale: scale);
      await tester.tap(find.byType(AppOverflowMenu));
      await tester.pumpAndSettle();
      expect(find.text(Copy.projectOpenWith), findsOneWidget);
      final String suffix = scale == 2 ? '_text2' : '';
      try {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/project_${surface.name}_open_with_menu$suffix'
            '_${mode.name}.png',
          ),
        );
      } catch (error) {
        failures.add('${surface.name} ${mode.name} scale $scale: $error');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }
  if (failures.isNotEmpty) {
    fail('golden moved:\n${failures.join('\n')} (FE-TEST-02)');
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required _Surface surface,
  required AppThemeMode mode,
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
  final FakeProjectRepository repo = FakeProjectRepository();
  addTearDown(repo.dispose);
  _ok(await repo.create(aProject(name: 'Alpha')));
  repo.seedHomeCounts(
    'project-1',
    review: 2,
    process: 3,
    toExport: 1,
    toShare: 4,
  );
  final GoRouter router = GoRouter(
    initialLocation: surface == _Surface.home
        ? AppRoutes.project('project-1')
        : AppRoutes.projects,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.projects,
        builder: (BuildContext _, GoRouterState _) {
          return const Scaffold(body: ProjectListView());
        },
        routes: <RouteBase>[
          GoRoute(
            path: ':projectId',
            builder: (BuildContext _, GoRouterState _) {
              return const ProjectHomeScreen();
            },
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(
            stored: <String, Object?>{
              SettingKeys.openProjectId.name: 'project-1',
            },
          ),
        ),
        projectHomeContextProvider.overrideWith((Ref _) => 'Ward 1'),
        downloadServiceProvider.overrideWith(
          (Ref _) => DownloadService.fake(canOpenExternally: true),
        ),
        projectOpenableFileLookupProvider.overrideWith(
          (Ref _) => ProjectOpenableFileLookup.fake(
            file: (
              fileName: 'book.xlsx',
              bytes: Uint8List.fromList(<int>[1, 2, 3]),
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: buildTheme(
          brightness: mode == AppThemeMode.dark
              ? Brightness.dark
              : Brightness.light,
          outdoor: mode == AppThemeMode.outdoor,
        ),
        routerConfig: router,
      ),
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

enum _Surface { list, home }
