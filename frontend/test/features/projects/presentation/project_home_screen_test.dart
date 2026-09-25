import 'dart:async';
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
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
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

  testWidgets('a populated home shows context, counts and one primary action', (
    WidgetTester tester,
  ) async {
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
    await _pump(
      tester,
      repo: repo,
      openProjectId: 'project-1',
      contextLabel: 'Ward 1',
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Ward 1'), findsOneWidget);
    _expectCountCards(tester);
    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(find.text(Copy.captureStart), findsOneWidget);
    expect(find.text(Copy.captureNeedsTemplate), findsOneWidget);
    expect(
      tester.widget<AppPrimaryAction>(find.byType(AppPrimaryAction)).onPressed,
      isNull,
    );
    expect(find.text(Copy.unprocessedCount(0)), findsNothing);

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
        thumbPath: null,
        fields: <ProjectRecordFieldValue>[],
      ),
    ]);
    await _pump(tester, repo: repo, openProjectId: 'project-1');
    await tester.pump();
    await tester.pump();
    expect(find.text(Copy.captureMore), findsOneWidget);
    expect(find.text(Copy.captureStart), findsNothing);
  });

  testWidgets('association failure stays visible and retryable', (
    WidgetTester tester,
  ) async {
    await _pumpPopulated(
      tester,
      overrides: <Override>[
        projectHomeAssociationsProvider.overrideWith(
          (Ref _) => const AsyncError<ProjectHomeAssociations>(
            StorageFailure(
              message: 'Associations unavailable.',
              recoveryAction: 'Retry.',
            ),
            StackTrace.empty,
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.projectAssociationCountUnavailable), findsOneWidget);
    expect(find.text(Copy.projectAssociationRetry), findsOneWidget);
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

  testWidgets('each count opens its filtered list', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    _ok(await templates.save(aTemplate(projectId: 'project-1')));
    repo.seedHomeCounts(
      'project-1',
      review: 2,
      process: 3,
      toExport: 1,
      toShare: 4,
    );

    Future<void> expectOpens({
      required Finder tap,
      required String path,
      String? filter,
    }) async {
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
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, path);
      expect(router.state.uri.queryParameters[AppRoutes.filterQuery], filter);
    }

    await expectOpens(
      tap: find.byKey(const ValueKey<String>('home-review')),
      path: AppRoutes.projectRecords('project-1'),
      filter: AppRoutes.reviewFilter,
    );
    await expectOpens(
      tap: find.byKey(const ValueKey<String>('home-process')),
      path: AppRoutes.projectQueue('project-1'),
      filter: AppRoutes.processFilter,
    );
    await expectOpens(
      tap: find.byKey(const ValueKey<String>('home-export')),
      path: AppRoutes.projectRecords('project-1'),
      filter: AppRoutes.exportFilter,
    );
    await expectOpens(
      tap: find.byKey(const ValueKey<String>('home-share')),
      path: AppRoutes.projectExports('project-1'),
      filter: AppRoutes.shareFilter,
    );
    await expectOpens(
      tap: find.text(Copy.captureStart),
      path: AppRoutes.capture('project-1'),
    );
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

  for (final ({double width, double gutter}) layout
      in <({double width, double gutter})>[
        (width: 393, gutter: Space.x4),
        (width: 800, gutter: Space.x4),
        (width: 1200, gutter: Space.x5),
      ]) {
    testWidgets(
      'at ${layout.width} dp the template label, radios, caption and cards '
      'share one start with no frame',
      (WidgetTester tester) async {
        _setSurface(tester, Size(layout.width, 886));
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

        final double body = tester
            .getTopLeft(find.byType(ProjectHomeScreen))
            .dx;
        final double label = tester.getTopLeft(find.text(Copy.navTemplates)).dx;
        final double radio = tester
            .getTopLeft(find.byType(Radio<String>).first)
            .dx;
        final double caption = tester.getTopLeft(find.text('Ward 1')).dx;
        final double card = tester
            .getTopLeft(find.byKey(const ValueKey<String>('home-review')))
            .dx;
        expect(label - body, closeTo(layout.gutter, 1));
        expect(radio, closeTo(label, 1));
        expect(caption, closeTo(label, 1));
        expect(card, closeTo(label, 1));
        expect(
          find.descendant(
            of: find.byType(AppRadioGroup<String>),
            matching: find.byType(Divider),
          ),
          findsNothing,
        );
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
        for (int i = 0; i < 12; i++)
          (
            id: 'r$i',
            templateId: 't1',
            status: 'captured',
            photoCount: 0,
            thumbPath: null,
            fields: <ProjectRecordFieldValue>[
              (fieldKey: 'name', raw: 'Item $i', refined: '', approved: ''),
            ],
          ),
      ]);
      await _pump(
        tester,
        repo: repo,
        openProjectId: 'project-1',
        contextLabel: 'Ward 1',
      );
      await tester.pumpAndSettle();

      final Finder search = find.byKey(const ValueKey<String>('home-search'));
      final double top = tester.getTopLeft(search).dy;
      expect(top, lessThan(tester.getTopLeft(find.text('Ward 1')).dy));
      final double titleRow = tester
          .getBottomLeft(find.byType(AppOverflowMenu))
          .dy;
      expect(top - titleRow, lessThanOrEqualTo(Space.x2));

      await tester.drag(find.text('Ward 1'), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(search).dy, top);
      expect(tester.getTopLeft(find.text('Ward 1')).dy, lessThan(top));

      await tester.enterText(
        find.descendant(of: search, matching: find.byType(EditableText)),
        'Item 11',
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Item 11'), findsWidgets);
      expect(find.text('Item 2'), findsNothing);
    },
  );

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

  testWidgets('count cards form a 2×2 grid at 393 dp', (
    WidgetTester tester,
  ) async {
    _setSurface(tester, const Size(393, 886));
    await _pumpPopulated(tester);
    _expectCountCards(tester);
    expect(_cardTop(tester, 'home-review'), _cardTop(tester, 'home-process'));
    expect(_cardTop(tester, 'home-export'), _cardTop(tester, 'home-share'));
    expect(
      _cardTop(tester, 'home-export'),
      greaterThan(_cardTop(tester, 'home-review')),
    );
    expect(_cardLeft(tester, 'home-review'), _cardLeft(tester, 'home-export'));
    expect(
      _cardLeft(tester, 'home-process'),
      greaterThan(_cardLeft(tester, 'home-review')),
    );
  });

  testWidgets('count cards sit in one row at 800 dp and 1200 dp', (
    WidgetTester tester,
  ) async {
    for (final Size size in <Size>[
      const Size(800, 1200),
      const Size(1200, 800),
    ]) {
      _setSurface(tester, size);
      await _pumpPopulated(tester);
      _expectCountCards(tester);
      expect(_cardTop(tester, 'home-review'), _cardTop(tester, 'home-process'));
      expect(_cardTop(tester, 'home-review'), _cardTop(tester, 'home-export'));
      expect(_cardTop(tester, 'home-review'), _cardTop(tester, 'home-share'));
      expect(
        _cardLeft(tester, 'home-process'),
        greaterThan(_cardLeft(tester, 'home-review')),
      );
      expect(
        _cardLeft(tester, 'home-export'),
        greaterThan(_cardLeft(tester, 'home-process')),
      );
      expect(
        _cardLeft(tester, 'home-share'),
        greaterThan(_cardLeft(tester, 'home-export')),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'count cards do not overflow in landscape or at 200 percent text',
    (WidgetTester tester) async {
      _setSurface(tester, const Size(800, 400));
      await _pumpPopulated(tester);
      expect(tester.takeException(), isNull);
      _expectCountCards(tester);
      await tester.pumpWidget(const SizedBox.shrink());

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      _setSurface(tester, const Size(360, 800));
      await _pumpPopulated(tester);
      expect(tester.takeException(), isNull);
      _expectCountCards(tester);
    },
  );

  testWidgets('popping a count list returns to the home with counts intact', (
    WidgetTester tester,
  ) async {
    final List<({String key, String path, String filter})> cards =
        <({String key, String path, String filter})>[
          (
            key: 'home-review',
            path: AppRoutes.projectRecords('project-1'),
            filter: AppRoutes.reviewFilter,
          ),
          (
            key: 'home-process',
            path: AppRoutes.projectQueue('project-1'),
            filter: AppRoutes.processFilter,
          ),
          (
            key: 'home-export',
            path: AppRoutes.projectRecords('project-1'),
            filter: AppRoutes.exportFilter,
          ),
          (
            key: 'home-share',
            path: AppRoutes.projectExports('project-1'),
            filter: AppRoutes.shareFilter,
          ),
        ];

    for (final Size size in <Size>[
      const Size(400, 800),
      const Size(800, 400),
      const Size(800, 1200),
      const Size(1200, 800),
    ]) {
      _setSurface(tester, size);
      final GoRouter router = await _pumpPopulated(tester);
      await tester.tap(find.byKey(const ValueKey<String>('home-review')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.projectRecords('project-1'));
      await tester.tap(find.byType(AppIconButton));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.project('project-1'));
      _expectCountCards(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    }

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    _setSurface(tester, const Size(400, 800));
    for (final ({String key, String path, String filter}) card in cards) {
      final GoRouter router = await _pumpPopulated(tester);
      await tester.tap(find.byKey(ValueKey<String>(card.key)));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, card.path);
      expect(
        router.state.uri.queryParameters[AppRoutes.filterQuery],
        card.filter,
      );
      expect(find.byType(AppIconButton), findsOneWidget);
      expect(find.byType(AppIconButton), meetsTapTarget());
      expect(
        find.byType(AppIconButton),
        hasSemanticLabel(
          MaterialLocalizations.of(
            tester.element(find.byType(AppIconButton)),
          ).backButtonTooltip,
        ),
      );
      await tester.tap(find.byType(AppIconButton));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.project('project-1'));
      _expectCountCards(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
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
  String? contextLabel,
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
        if (contextLabel != null)
          projectHomeContextProvider.overrideWith((Ref _) => contextLabel),
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
  repo.seedHomeCounts(
    'project-1',
    review: 2,
    process: 3,
    toExport: 1,
    toShare: 4,
  );
  final GoRouter router = await _pump(
    tester,
    repo: repo,
    openProjectId: 'project-1',
    contextLabel: 'Ward 1',
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

void _expectCountCards(WidgetTester tester) {
  expect(find.text(Copy.homeReview), findsOneWidget);
  expect(find.text(Copy.homeProcess), findsOneWidget);
  expect(find.text(Copy.homeExport), findsOneWidget);
  expect(find.text(Copy.homeShare), findsOneWidget);
  expect(find.text(Copy.homeReviewPending(2)), findsOneWidget);
  expect(find.text(Copy.homeProcessPending(3)), findsOneWidget);
  expect(find.text(Copy.homeExportPending(1)), findsOneWidget);
  expect(find.text(Copy.homeSharePending(4)), findsOneWidget);
  expect(
    find.byKey(const ValueKey<String>('home-review')),
    hasSemanticLabel(Copy.homeReviewPending(2)),
  );
  expect(
    find.byKey(const ValueKey<String>('home-process')),
    hasSemanticLabel(Copy.homeProcessPending(3)),
  );
  expect(
    find.byKey(const ValueKey<String>('home-export')),
    hasSemanticLabel(Copy.homeExportPending(1)),
  );
  expect(
    find.byKey(const ValueKey<String>('home-share')),
    hasSemanticLabel(Copy.homeSharePending(4)),
  );
}

double _cardTop(WidgetTester tester, String key) {
  return tester.getTopLeft(find.byKey(ValueKey<String>(key))).dy;
}

double _cardLeft(WidgetTester tester, String key) {
  return tester.getTopLeft(find.byKey(ValueKey<String>(key))).dx;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
