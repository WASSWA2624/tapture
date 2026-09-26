import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/presentation/project_export_screen.dart';
import 'package:tapture/features/projects/presentation/project_home_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final StreamController<List<ProjectListRow>> pending =
        StreamController<List<ProjectListRow>>();
    addTearDown(pending.close);
    await _pump(
      tester,
      overrides: <Override>[
        projectListProvider.overrideWith((Ref _) => pending.stream),
      ],
    );
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
  });

  testWidgets('an empty home renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    await _pump(tester, repo: repo);
    await tester.pump();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.homeEmptyHeadline), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
  });

  testWidgets('a populated home shows the search and one primary action', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, openProjectId: 'project-1');
    await tester.pump();
    await tester.pump();

    expect(find.text('Alpha'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('home-search')), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(find.text(Copy.captureStart), findsOneWidget);
    expect(find.text(Copy.captureNeedsTemplate), findsOneWidget);
    expect(
      tester.widget<AppPrimaryAction>(find.byType(AppPrimaryAction)).onPressed,
      isNull,
    );

    final Size screen = tester.getSize(find.byType(MaterialApp));
    final Offset action = tester.getCenter(find.byType(AppPrimaryAction));
    expect(action.dy, greaterThan(screen.height * 2 / 3));
  });

  testWidgets('a project with a record offers capture more', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedRecords('project-1', const <ProjectRecordRow>[
      (
        id: 'r1',
        templateId: 't1',
        status: 'captured',
        photoCount: 1,
        thumb: null,
        fields: <ProjectRecordFieldValue>[],
      ),
    ]);
    await _pump(tester, repo: repo, openProjectId: 'project-1');
    await tester.pump();
    await tester.pump();
    expect(find.text(Copy.captureMore), findsOneWidget);
    expect(find.text(Copy.captureStart), findsNothing);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        projectListProvider.overrideWith(
          (Ref _) => Stream<List<ProjectListRow>>.error(
            const StorageFailure(
              message: 'The project home could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The project home could not be read.'), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
  });

  testWidgets("capture opens this project's capture route", (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    _ok(await templates.save(aTemplate(projectId: 'project-1')));
    final GoRouter router = await _pump(
      tester,
      repo: repo,
      openProjectId: 'project-1',
      overrides: <Override>[
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text(Copy.captureStart));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.capture('project-1'));
  });

  testWidgets('each home menu item reaches its route', (
    WidgetTester tester,
  ) async {
    Future<void> expectOpens({
      required String label,
      required String path,
      Map<String, String> query = const <String, String>{},
    }) async {
      final GoRouter router = await _pumpPopulated(tester);
      await _chooseOverflow(tester, label);
      expect(router.state.uri.path, path);
      for (final MapEntry<String, String> entry in query.entries) {
        expect(router.state.uri.queryParameters[entry.key], entry.value);
      }
    }

    await expectOpens(
      label: Copy.projectsDuplicate,
      path: AppRoutes.projectCreate,
      query: <String, String>{
        AppRoutes.sourceQuery: 'project-1',
        AppRoutes.nameQuery: Copy.projectCopyName('Alpha'),
      },
    );
    await expectOpens(
      label: Copy.projectEditTitle,
      path: AppRoutes.projectEdit('project-1'),
    );
    await expectOpens(
      label: Copy.projectSettingsTitle,
      path: AppRoutes.projectSettings('project-1'),
    );
  });

  testWidgets('pinned fields and contexts live in the menu, not the body', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpPopulated(tester);

    expect(find.text(Copy.contextPinnedTitle), findsNothing);
    expect(find.text(Copy.contextHierarchyTitle), findsNothing);

    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    final double templates = tester.getTopLeft(find.text(Copy.navTemplates)).dy;
    final double pinned = tester
        .getTopLeft(find.text(Copy.contextPinnedTitle))
        .dy;
    final double contexts = tester
        .getTopLeft(find.text(Copy.contextHierarchyTitle))
        .dy;
    final double export = tester.getTopLeft(find.text(Copy.projectExport)).dy;
    expect(templates, lessThan(pinned));
    expect(pinned, lessThan(contexts));
    expect(contexts, lessThan(export));

    await tester.tap(find.text(Copy.contextHierarchyTitle));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.projectContext('project-1'));
  });

  testWidgets('the menu opens the pinned fields sheet', (
    WidgetTester tester,
  ) async {
    await _pumpPopulated(tester);

    await _chooseOverflow(tester, Copy.contextPinnedTitle);

    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.text(Copy.contextPinnedTitle), findsWidgets);
  });

  for (final double width in <double>[393, 800, 1200]) {
    testWidgets(
      'at $width dp the home has no count cards, template list or context',
      (WidgetTester tester) async {
        _setSurface(tester, Size(width, 886));
        final FakeTemplateRepository templates = FakeTemplateRepository();
        addTearDown(templates.dispose);
        _ok(await templates.save(aTemplate(id: 't1', name: 'Assets')));
        _ok(await templates.save(aTemplate(id: 't2', name: 'Rooms')));
        await _pumpPopulated(
          tester,
          overrides: <Override>[
            templateRepositoryProvider.overrideWith((Ref _) => templates),
          ],
        );
        await tester.pumpAndSettle();

        for (final String gone in <String>[
          'Needs review',
          'Ready to process',
          'Ready to export',
          'Exports to share',
          Copy.statusNoContext,
          'Assets',
          'Rooms',
        ]) {
          expect(find.text(gone), findsNothing, reason: gone);
        }
        expect(find.byType(Radio<String>), findsNothing);
        expect(find.text(Copy.navTemplates), findsNothing);
        expect(find.text(Copy.captureStart), findsOneWidget);
        await tester.tap(find.byType(AppOverflowMenu));
        await tester.pumpAndSettle();
        expect(find.text(Copy.navTemplates), findsOneWidget);
        expect(find.text(Copy.contextHierarchyTitle), findsOneWidget);
        expect(find.text(Copy.projectExport), findsOneWidget);
      },
    );
  }

  testWidgets(
    'the search is pinned at the top and stays while the body scrolls',
    (WidgetTester tester) async {
      _setSurface(tester, const Size(393, 640));
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _ok(await repo.create(aProject(name: 'Alpha')));
      repo.seedRecords('project-1', <ProjectRecordRow>[
        for (int i = 0; i < 12; i++) _record('r$i', name: 'Item $i'),
      ]);
      await _pump(tester, repo: repo, openProjectId: 'project-1');
      await tester.pumpAndSettle();

      final Finder search = find.byKey(const ValueKey<String>('home-search'));
      final double top = tester.getTopLeft(search).dy;
      expect(top, lessThan(tester.getTopLeft(find.text('Item 0')).dy));
      final double titleRow = tester
          .getBottomLeft(find.byType(AppOverflowMenu))
          .dy;
      expect(top - titleRow, lessThanOrEqualTo(Space.x2));

      await tester.drag(find.text('Item 0'), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(search).dy, top);

      await tester.enterText(
        find.descendant(of: search, matching: find.byType(EditableText)),
        'Item 11',
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Item 11'), findsWidgets);
      expect(find.text('Item 2'), findsNothing);
    },
  );

  testWidgets('tapping a record row opens its page', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedRecords('project-1', <ProjectRecordRow>[
      _record('r1', name: 'Pump house'),
    ]);
    final GoRouter router = await _pump(
      tester,
      repo: repo,
      openProjectId: 'project-1',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pump house'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.projectRecord('project-1', 'r1'));
    expect(find.text('record page'), findsOneWidget);
  });

  testWidgets('a record row Edit opens it on the capture page', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedRecords('project-1', <ProjectRecordRow>[
      _record('r1', name: 'Pump house'),
    ]);
    final GoRouter router = await _pump(
      tester,
      repo: repo,
      openProjectId: 'project-1',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Copy.recordEdit));
    await tester.pumpAndSettle();
    expect(
      router.state.uri.path,
      AppRoutes.projectRecordEdit('project-1', 'r1'),
    );
    expect(find.text('edit page'), findsOneWidget);
  });

  testWidgets('the search says it looks through records', (
    WidgetTester tester,
  ) async {
    await _pumpPopulated(tester);
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectRecordsSearchHint), findsWidgets);
  });

  testWidgets('a search miss names the query, and clearing it restores rows', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedRecords('project-1', <ProjectRecordRow>[
      _record('r1', name: 'Pump house'),
    ]);
    await _pump(tester, repo: repo, openProjectId: 'project-1');
    await tester.pumpAndSettle();
    final Finder field = find.descendant(
      of: find.byKey(const ValueKey<String>('home-search')),
      matching: find.byType(EditableText),
    );

    await tester.enterText(field, 'buildin');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(Copy.projectRecordsNoMatch('buildin')), findsOneWidget);
    expect(find.text(Copy.searchNoMatchMessage), findsOneWidget);
    expect(find.text(Copy.projectRecordsEmptyHeadline), findsNothing);

    await tester.enterText(field, '');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pump house'), findsOneWidget);
    expect(find.text(Copy.projectRecordsNoMatch('buildin')), findsNothing);
  });

  testWidgets('a project with no records keeps its empty state', (
    WidgetTester tester,
  ) async {
    await _pumpPopulated(tester);
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectRecordsEmptyHeadline), findsOneWidget);
  });

  testWidgets('a record row shows its photo from the thumbnail cache', (
    WidgetTester tester,
  ) async {
    final Directory dir = Directory.systemTemp.createTempSync('tapture-row-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File thumb = File('${dir.path}/thumb.png')
      ..writeAsBytesSync(_onePixelPng);
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedRecords('project-1', <ProjectRecordRow>[
      _record(
        'r1',
        name: 'With photo',
        thumb: (
          sha256: 'sha-1',
          storagePath: 'projects/test-project/photos/a.jpg',
          quarterTurns: 1,
        ),
      ),
      _record(
        'r2',
        name: 'Photo gone',
        thumb: (
          sha256: 'sha-2',
          storagePath: 'projects/test-project/photos/gone.jpg',
          quarterTurns: 0,
        ),
      ),
    ]);
    await _pump(
      tester,
      repo: repo,
      openProjectId: 'project-1',
      overrides: <Override>[
        photoThumbnailsProvider.overrideWith(
          (Ref _) => PhotoThumbnails.fake(<String, String>{
            'projects/test-project/photos/a.jpg': thumb.path,
          }),
        ),
      ],
    );
    await tester.pumpAndSettle();

    final Finder first = find.ancestor(
      of: find.text('With photo'),
      matching: find.byType(AppListTile),
    );
    expect(
      find.descendant(of: first, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppPhotoThumb>(
            find.descendant(of: first, matching: find.byType(AppPhotoThumb)),
          )
          .quarterTurns,
      1,
    );
    final Finder second = find.ancestor(
      of: find.text('Photo gone'),
      matching: find.byType(AppListTile),
    );
    expect(
      find.descendant(of: second, matching: find.text(Copy.missingPhoto)),
      findsOneWidget,
    );
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
      ]) {
    testWidgets('in ${layout.name} the search and capture stay on screen', (
      WidgetTester tester,
    ) async {
      _setSurface(tester, layout.size);
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpPopulated(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Rect search = tester.getRect(
        find.byKey(const ValueKey<String>('home-search')),
      );
      final Rect capture = tester.getRect(find.byType(AppPrimaryAction));
      expect(search.top, greaterThanOrEqualTo(0));
      expect(capture.bottom, lessThanOrEqualTo(layout.size.height));
      expect(search.bottom, lessThan(capture.top));
    });
  }

  testWidgets('export from the home menu opens this project', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpPopulated(tester);
    await _chooseOverflow(tester, Copy.projectExport);
    expect(router.state.uri.path, AppRoutes.projectExports('project-1'));
    expect(
      tester
          .widget<ProjectExportScreen>(find.byType(ProjectExportScreen))
          .projectId,
      'project-1',
    );
  });

  testWidgets('archive from the home menu lands on the list', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpPopulated(tester);
    await _chooseOverflow(tester, Copy.projectArchive);
    expect(router.state.uri.path, AppRoutes.projects);
  });

  testWidgets('delete from the home menu lands on the list', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpPopulated(tester);
    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectDeleteMenu));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Alpha');
    await tester.pump();
    await tester.tap(find.text(Copy.projectDelete).last);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.projects);
  });

  testWidgets('the home menu is labelled and meets 48dp', (
    WidgetTester tester,
  ) async {
    await _pumpPopulated(tester);
    expect(find.byType(AppOverflowMenu), meetsTapTarget());
    expect(find.byType(AppOverflowMenu), hasSemanticLabel(Copy.overflowMenu));
  });

  testWidgets(
    'Open with is hidden on the home when nothing can be handed off',
    (WidgetTester tester) async {
      await _pumpPopulated(tester);
      await tester.tap(find.byType(AppOverflowMenu));
      await tester.pumpAndSettle();
      expect(find.text(Copy.projectOpenWith), findsNothing);
      expect(find.text(Copy.projectDownloadCopy), findsNothing);
    },
  );

  testWidgets('Open with sits after Settings when a file exists', (
    WidgetTester tester,
  ) async {
    await _pumpPopulated(tester, overrides: _openableOverrides());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    expect(find.text(Copy.projectOpenWith), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('project-open-project-1')),
      meetsTapTarget(),
    );
    expect(find.byType(AppOverflowMenu), hasSemanticLabel(Copy.overflowMenu));
  });

  testWidgets('a failed home Open with renders AppErrorState', (
    WidgetTester tester,
  ) async {
    await _pumpPopulated(
      tester,
      overrides: _openableOverrides(
        downloads: DownloadService.fake(
          canOpenExternally: true,
          openNoHandler: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectOpenWith));
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets(
    'home Open with meets tap target, label and tooltip matchers at each width',
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
          _setSurface(tester, size);
          await _pumpPopulated(
            tester,
            overrides: _openableOverrides(),
            mode: mode,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(AppOverflowMenu));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey<String>('project-open-project-1')),
            meetsTapTarget(),
          );
          expect(
            find.byType(AppOverflowMenu),
            hasSemanticLabel(Copy.overflowMenu),
          );
          expect(find.byTooltip(Copy.overflowMenu), findsWidgets);
          await expectNoA11yIssues(tester);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}

List<Override> _openableOverrides({DownloadService? downloads}) {
  return <Override>[
    downloadServiceProvider.overrideWith(
      (Ref _) => downloads ?? DownloadService.fake(canOpenExternally: true),
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
  ];
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  FakeProjectRepository? repo,
  String? openProjectId,
  List<Override> overrides = const <Override>[],
  AppThemeMode mode = AppThemeMode.light,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.project(openProjectId ?? 'project-1'),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.projects,
        builder: (BuildContext _, GoRouterState _) {
          return const SizedBox.shrink();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (BuildContext _, GoRouterState _) {
              return const Text('create');
            },
          ),
          GoRoute(
            path: ':projectId',
            builder: (BuildContext _, GoRouterState _) {
              return const ProjectHomeScreen();
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'capture',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('capture');
                },
              ),
              GoRoute(
                path: 'edit',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('edit');
                },
              ),
              GoRoute(
                path: 'context',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('context');
                },
              ),
              GoRoute(
                path: 'settings',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('settings');
                },
              ),
              GoRoute(
                path: 'records',
                builder: (BuildContext _, GoRouterState _) {
                  return const AppPage(
                    title: Copy.navRecords,
                    compactBar: true,
                    body: Text('records'),
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: ':recordId',
                    builder: (BuildContext _, GoRouterState _) {
                      return const Text('record page');
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'edit',
                        builder: (BuildContext _, GoRouterState _) {
                          return const Text('edit page');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'queue',
                builder: (BuildContext _, GoRouterState _) {
                  return const AppPage(
                    title: Copy.navQueue,
                    compactBar: true,
                    body: Text('queue'),
                  );
                },
              ),
              GoRoute(
                path: 'exports',
                builder: (BuildContext _, GoRouterState state) {
                  return ProjectExportScreen(
                    projectId: state.pathParameters['projectId']!,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        if (repo != null)
          projectRepositoryProvider.overrideWith((Ref _) => repo),
        if (openProjectId != null)
          projectSettingsStoreProvider.overrideWith(
            (Ref _) => SettingsStore.fake(
              stored: <String, Object?>{
                SettingKeys.openProjectId.name: openProjectId,
              },
            ),
          ),
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
  return router;
}

Future<GoRouter> _pumpPopulated(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  AppThemeMode mode = AppThemeMode.light,
}) async {
  final FakeProjectRepository repo = FakeProjectRepository();
  addTearDown(repo.dispose);
  _ok(await repo.create(aProject(name: 'Alpha')));
  final GoRouter router = await _pump(
    tester,
    repo: repo,
    openProjectId: 'project-1',
    overrides: overrides,
    mode: mode,
  );
  await tester.pump();
  await tester.pump();
  return router;
}

Future<void> _chooseOverflow(WidgetTester tester, String label) async {
  await tester.tap(find.byType(AppOverflowMenu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

ProjectRecordRow _record(String id, {String? name, RecordPhotoRef? thumb}) {
  return (
    id: id,
    templateId: 't1',
    status: 'captured',
    photoCount: thumb == null ? 0 : 1,
    thumb: thumb,
    fields: <ProjectRecordFieldValue>[
      if (name != null)
        (fieldKey: 'name', raw: name, refined: '', approved: ''),
    ],
  );
}

/// A valid 1×1 PNG, so the thumbnail decodes without an error placeholder.
final Uint8List _onePixelPng = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
