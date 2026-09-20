import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets(
    'the row menu offers Rename, Pin, Archive and Delete and has no border',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _ok(await repo.create(aProject(name: 'Alpha')));
      await _pump(tester, repo: repo);
      await tester.pumpAndSettle();

      final Finder menu = _rowMenu('project-1');
      expect(tester.widget<AppOverflowMenu>(menu).outlined, isFalse);
      expect(menu, meetsTapTarget());
      expect(menu, hasSemanticLabel(Copy.overflowMenu));
      expect(find.byTooltip(Copy.overflowMenu), findsOneWidget);
      final IconButton button = tester.widget<IconButton>(
        find.descendant(of: menu, matching: find.byType(IconButton)),
      );
      expect(
        button.style?.side?.resolve(const <WidgetState>{}),
        BorderSide.none,
      );

      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.text(Copy.projectRename), findsOneWidget);
      expect(find.text(Copy.projectPin), findsOneWidget);
      expect(find.text(Copy.projectArchive), findsOneWidget);
      expect(find.text(Copy.projectDelete), findsOneWidget);
      expect(find.text(Copy.projectEditTitle), findsNothing);
    },
  );

  testWidgets('the row menu meets tap target, label and tooltip matchers', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await expectNoA11yIssues(tester);
  });

  testWidgets('Pin moves the row to the top of the list', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(id: 'project-1', name: 'Alpha')));
    _ok(await repo.create(aProject(id: 'project-2', name: 'Beta')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(_rowMenu('project-2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectPin));
    await tester.pumpAndSettle();

    final List<Element> tiles = find.byType(AppListTile).evaluate().toList();
    expect(
      tester.widget<AppListTile>(find.byWidget(tiles.first.widget)).title,
      'Beta',
    );
    expect(
      repo.stored.singleWhere((Project p) => p.id == 'project-2').pinnedAt,
      isNotNull,
    );

    await tester.tap(_rowMenu('project-2'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectUnpin), findsOneWidget);
    expect(find.text(Copy.projectPin), findsNothing);
  });

  testWidgets('long-press on a row does not open the menu', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectRename), findsNothing);
    expect(find.text(Copy.projectPin), findsNothing);
    expect(find.text(Copy.projectArchive), findsNothing);
    expect(find.text(Copy.projectDelete), findsNothing);
  });

  testWidgets('Rename saves a new name and leaves the folder', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(_rowMenu('project-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectRename));
    await tester.pumpAndSettle();

    expect(find.text(Copy.projectRenameTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Omega');
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();

    expect(find.text('Omega'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    expect(repo.stored.single.name, 'Omega');
    expect(repo.stored.single.folderName, 'test-project');
  });

  testWidgets('Rename cancel leaves the name', (WidgetTester tester) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(_rowMenu('project-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectRename));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Omega');
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text(Copy.projectRenameTitle), findsNothing);
    expect(repo.stored.single.name, 'Alpha');
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeProjectRepository repo,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.projects,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.projects,
        builder: (BuildContext _, GoRouterState _) {
          return const Scaffold(body: ProjectListView());
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
}

Finder _rowMenu(String id) {
  return find.descendant(
    of: find.byKey(ValueKey<String>('project-row-$id')),
    matching: find.byType(AppOverflowMenu),
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
