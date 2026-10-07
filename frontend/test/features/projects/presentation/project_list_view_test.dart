import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets(
    '2000 projects build bounded rows while scrolled actions retain identity',
    (WidgetTester tester) async {
      final FakeProjectRepository repository = FakeProjectRepository();
      addTearDown(repository.dispose);
      final DateTime at = DateTime.utc(2026, 10, 1);
      for (var i = 0; i < 2000; i++) {
        _ok(
          await repository.create(
            aProject(
              id: 'project-$i',
              name: 'Project $i',
              updatedAt: at.subtract(Duration(minutes: i)),
            ),
          ),
        );
      }
      await _pump(tester, repo: repository);
      await tester.pumpAndSettle();
      expect(find.byType(AppListTile).evaluate().length, lessThan(30));
      expect(find.text(Copy.projectListNumber(1)), findsOneWidget);
      final Finder target = find.byKey(
        const ValueKey<String>('project-row-project-100'),
      );
      await tester.scrollUntilVisible(
        target,
        500,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      expect(find.byType(AppListTile).evaluate().length, lessThan(30));
      expect(
        find.byKey(const ValueKey<String>('project-row-project-0')),
        findsNothing,
      );
      expect(find.text(Copy.projectListNumber(101)), findsOneWidget);
      await tester.tap(_rowMenu('project-100'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.projectPin));
      await tester.pumpAndSettle();
      expect(
        repository.stored
            .singleWhere((Project project) => project.id == 'project-100')
            .pinnedAt,
        isNotNull,
      );
      expect(
        repository.stored.where((Project project) => project.pinnedAt != null),
        hasLength(1),
      );
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(target, findsOneWidget);
      expect(find.text(Copy.projectListNumber(1)), findsOneWidget);
      expect(
        tester.widget<AppListTile>(find.byType(AppListTile).first).title,
        'Project 100',
      );
      expect(find.byType(AppListTile).evaluate().length, lessThan(30));
      expect(tester.takeException(), isNull);
    },
  );

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
      expect(find.text(Copy.projectExport), findsOneWidget);
      expect(find.text(Copy.projectRename), findsOneWidget);
      expect(find.text(Copy.projectPin), findsOneWidget);
      expect(find.text(Copy.projectOpenWith), findsNothing);
      expect(find.text(Copy.projectDownloadCopy), findsNothing);
      expect(find.text(Copy.projectArchive), findsOneWidget);
      expect(find.text(Copy.projectDeleteMenu), findsOneWidget);
      expect(find.text(Copy.projectDelete), findsNothing);
      expect(find.text(Copy.projectEditTitle), findsNothing);
    },
  );

  for (final Size size in <Size>[const Size(400, 800), const Size(1200, 800)]) {
    testWidgets('at ${size.width.round()} dp a project photo leads its row, '
        'and a project without one keeps its number', (
      WidgetTester tester,
    ) async {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _ok(await repo.create(aProject(id: 'project-1', name: 'Alpha')));
      _ok(await repo.create(aProject(id: 'project-2', name: 'Beta')));
      _ok(
        await repo.setCoverPhoto(
          'project-1',
          Uint8List.fromList(<int>[1, 2, 3]),
        ),
      );
      await _pump(
        tester,
        repo: repo,
        size: size,
        overrides: <Override>[
          photoThumbnailsProvider.overrideWith(
            (Ref _) => PhotoThumbnails.fake(const <String, String>{}),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey<String>('project-photo-project-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('project-photo-project-2')),
        findsNothing,
      );
      expect(find.text(Copy.projectListNumber(2)), findsOneWidget);
      expect(find.text(Copy.projectListNumber(1)), findsNothing);
    });
  }

  testWidgets('browser project cover draws byte thumbnail', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(id: 'project-1', name: 'Alpha')));
    final ProjectSettings settings = _ok(
      await repo.setCoverPhoto('project-1', Uint8List.fromList(<int>[1, 2])),
    );
    final Uint8List thumb = Uint8List.fromList(
      img.encodePng(img.Image(width: 8, height: 4)),
    );
    await _pump(
      tester,
      repo: repo,
      overrides: <Override>[
        photoThumbnailsProvider.overrideWith(
          (Ref _) => PhotoThumbnails.fake(
            const <String, String>{},
            bytes: <String, Uint8List>{settings.coverPhoto!.path: thumb},
          ),
        ),
        thumbnailsFromBytesProvider.overrideWithValue(true),
      ],
    );
    await tester.pumpAndSettle();

    final AppPhotoThumb drawn = tester.widget<AppPhotoThumb>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('project-photo-project-1')),
        matching: find.byType(AppPhotoThumb),
      ),
    );
    expect(drawn.photo.thumbBytes, thumb);
    expect(find.text(Copy.missingPhoto), findsNothing);
  });

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
