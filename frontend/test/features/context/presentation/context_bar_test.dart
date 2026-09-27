import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_context_repository.dart';
import '../../projects/fakes/fake_project_repository.dart';

void main() {
  testWidgets('on Capture every level shows, set or not, with Manage', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, showsEmptyLevels: true);

    expect(
      find.text(Copy.contextLevelValue('District', 'Kampala')),
      findsOneWidget,
    );
    expect(find.text(Copy.contextSetLevel('Sub-county')), findsOneWidget);
    expect(find.text(Copy.contextManage), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('context-bar-level-subcounty')),
      meetsTapTarget(),
    );
    expect(harness.router, isNotNull);
  });

  testWidgets('a Set chip opens the picker for its level', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: true);

    await tester.tap(
      find.byKey(const ValueKey<String>('context-bar-level-subcounty')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('Manage opens the project context levels', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      showsEmptyLevels: true,
      width: 1200,
    );

    await tester.tap(find.byKey(const ValueKey<String>('context-bar-manage')));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, RoutePaths.projectContext('p1'));
  });

  testWidgets('with no levels Capture offers Set up context', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      showsEmptyLevels: true,
      levels: const <ContextLevel>[],
    );

    expect(find.text(Copy.contextSetUp), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('context-bar-set-up')));
    await tester.pumpAndSettle();
    expect(harness.router.state.uri.path, RoutePaths.projectContext('p1'));
  });

  testWidgets('elsewhere an empty level stays hidden, as before', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: false);

    expect(find.text(Copy.contextSetLevel('Sub-county')), findsNothing);
    expect(find.text(Copy.contextManage), findsNothing);
    expect(find.textContaining('Kampala'), findsOneWidget);
  });

  testWidgets('at 200 percent text on a phone the chips scroll, not clip', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: true, width: 320, scale: 2);

    expect(tester.takeException(), isNull);
    final Finder manage = find.byKey(
      const ValueKey<String>('context-bar-manage'),
    );
    await tester.dragUntilVisible(
      manage,
      find.byType(SingleChildScrollView),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(manage).right, lessThanOrEqualTo(320));
  });

  testWidgets('under right-to-left the first level starts on the right', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: true, rtl: true);

    final Rect first = tester.getRect(
      find.byKey(const ValueKey<String>('context-bar-level-district')),
    );
    final Rect second = tester.getRect(
      find.byKey(const ValueKey<String>('context-bar-level-subcounty')),
    );
    expect(first.left, greaterThan(second.left));
  });
}

typedef _Harness = ({GoRouter router});

Future<_Harness> _pump(
  WidgetTester tester, {
  required bool showsEmptyLevels,
  List<ContextLevel> levels = const <ContextLevel>[
    ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
    ContextLevel(fieldKey: 'subcounty', order: 1, label: 'Sub-county'),
  ],
  double width = 400,
  double scale = 1,
  bool rtl = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 400);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final FakeContextRepository repo = FakeContextRepository();
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(repo.dispose);
  addTearDown(projects.dispose);
  _ok(await projects.create(aProject(id: 'p1', name: 'Inventory')));
  await repo.saveHierarchy('p1', levels);
  if (levels.isNotEmpty) {
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'district',
      value: 'Kampala',
    );
  }
  final GoRouter router = GoRouter(
    initialLocation: '/capture',
    routes: <RouteBase>[
      GoRoute(
        path: '/capture',
        builder: (BuildContext _, GoRouterState _) => Scaffold(
          body: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Align(
              alignment: Alignment.topCenter,
              child: ContextBar(showsEmptyLevels: showsEmptyLevels),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/projects/:projectId/context',
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('levels')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        contextRepositoryProvider.overrideWith((Ref _) => repo),
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(
            stored: <String, Object?>{SettingKeys.openProjectId.name: 'p1'},
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router);
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
