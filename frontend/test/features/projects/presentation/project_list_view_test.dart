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
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
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
      expect(find.text(Copy.projectOpenWith), findsNothing);
      expect(find.text(Copy.projectDownloadCopy), findsNothing);
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
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.bySemanticsLabel(Copy.pinnedProject), findsOneWidget);

    await tester.tap(_rowMenu('project-2'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectUnpin), findsOneWidget);
    expect(find.text(Copy.projectPin), findsNothing);
    await tester.tap(find.text(Copy.projectUnpin));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.push_pin), findsNothing);
    expect(find.bySemanticsLabel(Copy.pinnedProject), findsNothing);
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

  testWidgets('Open with is hidden when the project has no file', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(
      tester,
      repo: repo,
      overrides: <Override>[
        downloadServiceProvider.overrideWith(
          (Ref _) => DownloadService.fake(canOpenExternally: true),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(_rowMenu('project-1'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectOpenWith), findsNothing);
    expect(find.text(Copy.projectDownloadCopy), findsNothing);
  });

  testWidgets('Open with is present when a file can be handed off', (
    WidgetTester tester,
  ) async {
    await _pumpOpenable(tester);
    await tester.tap(_rowMenu('project-1'));
    await tester.pumpAndSettle();

    expect(find.text(Copy.projectOpenWith), findsOneWidget);
    expect(_openWithItem(), meetsTapTarget());
    expect(_rowMenu('project-1'), hasSemanticLabel(Copy.overflowMenu));
    expect(find.byTooltip(Copy.overflowMenu), findsOneWidget);
  });

  testWidgets('Download a copy is the web label', (WidgetTester tester) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(
      tester,
      repo: repo,
      overrides: _openableOverrides(
        downloads: DownloadService.fake(canDownloadCopy: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_rowMenu('project-1'));
    await tester.pumpAndSettle();

    expect(find.text(Copy.projectDownloadCopy), findsOneWidget);
    expect(find.text(Copy.projectOpenWith), findsNothing);
  });

  testWidgets('a failed Open with renders AppErrorState', (
    WidgetTester tester,
  ) async {
    String? handedName;
    await _pumpOpenable(
      tester,
      downloads: DownloadService.fake(
        canOpenExternally: true,
        openCancel: true,
        onOpenExternally: (String fileName, Uint8List _, String _) {
          handedName = fileName;
        },
      ),
    );
    await tester.tap(_rowMenu('project-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectOpenWith));
    await tester.pumpAndSettle();

    expect(handedName, 'book.xlsx');
    expect(handedName, isNot(contains('/')));
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.projectOpenFailedTitle), findsOneWidget);
  });

  testWidgets(
    'Open with meets tap target, label and tooltip matchers at each width',
    (WidgetTester tester) async {
      for (final Size size in <Size>[
        const Size(400, 800),
        const Size(800, 1200),
        const Size(1200, 800),
      ]) {
        for (final AppThemeMode mode in <AppThemeMode>[
          AppThemeMode.light,
          AppThemeMode.dark,
          AppThemeMode.outdoor,
        ]) {
          await _pumpOpenable(tester, size: size, mode: mode);
          await tester.tap(_rowMenu('project-1'));
          await tester.pumpAndSettle();
          expect(_openWithItem(), meetsTapTarget());
          expect(_rowMenu('project-1'), hasSemanticLabel(Copy.overflowMenu));
          expect(find.byTooltip(Copy.overflowMenu), findsWidgets);
          await expectNoA11yIssues(tester);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}

Future<void> _pumpOpenable(
  WidgetTester tester, {
  DownloadService? downloads,
  Size size = const Size(400, 800),
  AppThemeMode mode = AppThemeMode.light,
}) async {
  final FakeProjectRepository repo = FakeProjectRepository();
  addTearDown(repo.dispose);
  _ok(await repo.create(aProject(name: 'Alpha')));
  await _pump(
    tester,
    repo: repo,
    size: size,
    mode: mode,
    overrides: _openableOverrides(downloads: downloads),
  );
  await tester.pumpAndSettle();
}

List<Override> _openableOverrides({DownloadService? downloads}) {
  return <Override>[
    downloadServiceProvider.overrideWith(
      (Ref _) => downloads ?? DownloadService.fake(canOpenExternally: true),
    ),
    projectOpenableFileLookupProvider.overrideWith(
      (Ref _) => ProjectOpenableFileLookup.fake(file: _aFile()),
    ),
  ];
}

ProjectOpenableFile _aFile() {
  return (
    fileName: 'book.xlsx',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeProjectRepository repo,
  Size size = const Size(400, 800),
  AppThemeMode mode = AppThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
        ...overrides,
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
}

Finder _openWithItem() {
  return find.byKey(const ValueKey<String>('project-open-project-1'));
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
