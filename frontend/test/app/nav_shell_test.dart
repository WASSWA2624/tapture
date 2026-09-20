import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/projects.dart';

import '../features/projects/fakes/fake_project_repository.dart';
import '../support/factories.dart';

void main() {
  testWidgets('compact width uses a bottom bar', (WidgetTester tester) async {
    await _pump(tester, width: 400);

    expect(find.byKey(const ValueKey<String>('nav-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-rail')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsNothing);
    expect(find.byType(NavShell), findsOneWidget);
  });

  testWidgets('medium width uses a navigation rail', (
    WidgetTester tester,
  ) async {
    await _pump(tester, width: 800);

    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-bar')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsNothing);
  });

  testWidgets('expanded width uses a rail and a list pane', (
    WidgetTester tester,
  ) async {
    await _pump(tester, width: 1200);

    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-bar')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('nav-pane'))).width,
      Sizes.listPane,
    );
    expect(tester.getSize(find.byType(StatusLine)).width, 1200);
  });

  testWidgets('expanded capture and more drop the list pane', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester, width: 1200);

    router.go('/capture');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsNothing);

    router.go(AppRoutes.more);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsNothing);
    expect(find.text(Copy.navMore), findsWidgets);
    expect(find.text(Copy.operatorProfileTitle), findsOneWidget);
    expect(find.text(Copy.settingsAboutTitle), findsOneWidget);
  });

  testWidgets(
    'Capture stays larger but not accented when Projects is selected',
    (WidgetTester tester) async {
      for (final double width in <double>[400, 800, 1200]) {
        await _pump(tester, width: width);
        _expectCaptureSize(tester);
        final Icon capture = _navIcon(tester, 1);
        final Icon projects = _navIcon(tester, 0);
        expect(capture.icon, Icons.photo_camera_outlined);
        expect(projects.icon, Icons.folder);
        expect(capture.color, _unselectedInk(tester));
        expect(projects.color, _accent(tester));
        expect(<Color>{
          tester.element(find.byType(NavShell)).colors.primary,
          AppColors.dark.primary,
        }, isNot(contains(capture.color)));
      }
    },
  );

  testWidgets('Capture uses the accent and filled camera when it is selected', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[400, 800, 1200]) {
      final GoRouter router = await _pump(tester, width: width);
      router.go('/capture');
      await tester.pumpAndSettle();
      _expectCaptureSize(tester);
      final Icon capture = _navIcon(tester, 1);
      expect(capture.icon, Icons.photo_camera);
      expect(capture.color, _accent(tester));
    }
  });

  testWidgets('Projects shows a folder, filled only when it is selected', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[400, 800, 1200]) {
      final GoRouter router = await _pump(tester, width: width);
      await tester.pumpAndSettle();
      expect(_navIcon(tester, 0).icon, Icons.folder);
      router.go('/capture');
      await tester.pumpAndSettle();
      expect(_navIcon(tester, 0).icon, Icons.folder_outlined);
    }
  });

  testWidgets(
    'the stack and a half-typed field survive a switch and a width change',
    (WidgetTester tester) async {
      final GoRouter router = await _pump(tester, width: 400, projectId: 'p1');

      router.go(AppRoutes.project('p1'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('route-project')),
        findsOneWidget,
      );

      router.go(AppRoutes.records);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('route-records')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-records')),
        'half typed',
      );
      expect(find.text('half typed'), findsOneWidget);

      await tester.tap(_shellLabel(tester, Copy.navProjects));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.project('p1'));
      expect(
        find.byKey(const ValueKey<String>('route-project')),
        findsOneWidget,
      );

      await tester.tap(_shellLabel(tester, Copy.navRecords));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/records');
      expect(
        find.byKey(const ValueKey<String>('route-records')),
        findsOneWidget,
      );
      expect(find.text('half typed'), findsOneWidget);

      await _setWidth(tester, 800);
      expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
      expect(router.state.uri.path, '/records');
      expect(find.text('half typed'), findsOneWidget);

      await _setWidth(tester, 1200);
      expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-pane')), findsOneWidget);
      expect(router.state.uri.path, '/records');
      expect(find.text('half typed'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Projects on a project home shows the list at 400, 800 and 1200dp',
    (WidgetTester tester) async {
      for (final double width in <double>[400, 800, 1200]) {
        final GoRouter router = await _pump(
          tester,
          width: width,
          projectId: 'p1',
        );
        router.go(AppRoutes.project('p1'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('route-project')),
          findsOneWidget,
        );

        await tester.tap(_shellLabel(tester, Copy.navProjects));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, AppRoutes.projects);
        expect(
          find.byKey(const ValueKey<String>('route-projects')),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'a count-card list keeps Projects selected at 400, 800 and 1200dp',
    (WidgetTester tester) async {
      for (final double width in <double>[400, 800, 1200]) {
        final GoRouter router = await _pump(
          tester,
          width: width,
          projectId: 'p1',
        );
        router.go(AppRoutes.project('p1'));
        await tester.pumpAndSettle();
        unawaited(
          router.push(
            AppRoutes.projectRecordsFiltered('p1', AppRoutes.reviewFilter),
          ),
        );
        await tester.pumpAndSettle();
        expect(router.state.uri.path, AppRoutes.projectRecords('p1'));
        expect(_navIcon(tester, 0).icon, Icons.folder);
        expect(_navIcon(tester, 3).icon, Icons.settings_outlined);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'Templates from Settings stay on Settings and tapping Settings returns',
    (WidgetTester tester) async {
      for (final double width in <double>[400, 800, 1200]) {
        final GoRouter router = await _pump(tester, width: width);
        router.go(AppRoutes.more);
        await tester.pumpAndSettle();
        expect(find.text(Copy.operatorProfileTitle), findsOneWidget);

        router.go(AppRoutes.templates);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('route-templates')),
          findsOneWidget,
        );
        expect(_navIcon(tester, 3).icon, Icons.settings);
        expect(_navIcon(tester, 0).icon, Icons.folder_outlined);

        await tester.tap(_shellLabel(tester, Copy.navMore));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, AppRoutes.more);
        expect(find.text(Copy.operatorProfileTitle), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'the expanded pane lists projects under search, with no heading',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = await _seedProjects(<String>[
        'Alpha',
        'Beta',
        'Gamma',
      ]);
      addTearDown(repo.dispose);
      await _pump(tester, width: 1200, repo: repo);
      await tester.pumpAndSettle();

      expect(_paneTitle(Copy.navProjects), findsNothing);
      expect(
        find.descendant(of: _pane(), matching: find.byType(AppListTile)),
        findsNWidgets(3),
      );
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.byType(AppListTile), findsNWidgets(3));
      expect(find.text(Copy.emptyHeadline), findsNothing);
    },
  );

  testWidgets('pane search narrows, clears, and shows a no-match empty state', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>[
      'Alpha',
      'Beta',
    ]);
    addTearDown(repo.dispose);
    await _pump(tester, width: 1200, repo: repo);
    await tester.pumpAndSettle();

    await tester.enterText(_paneSearch(), 'Alp');
    await tester.pump(AppConstants.interaction.debounce);
    expect(
      find.descendant(of: _pane(), matching: find.text('Alpha')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _pane(), matching: find.text('Beta')),
      findsNothing,
    );

    await tester.tap(find.byTooltip(Copy.clearField(Copy.search)));
    await tester.pump();
    await tester.pump(AppConstants.interaction.debounce);
    expect(
      find.descendant(of: _pane(), matching: find.byType(AppListTile)),
      findsNWidgets(2),
    );

    await tester.enterText(_paneSearch(), 'zzzz');
    await tester.pump(AppConstants.interaction.debounce);
    expect(find.text(Copy.projectsNoMatchHeadline), findsOneWidget);
    expect(find.text(Copy.projectsNoMatchMessage), findsOneWidget);
    expect(
      find.descendant(of: _pane(), matching: find.text(Copy.projectsCreate)),
      findsOneWidget,
    );
  });

  testWidgets('the Records pane keeps its empty state', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>['Alpha']);
    addTearDown(repo.dispose);
    final GoRouter router = await _pump(tester, width: 1200, repo: repo);
    await tester.pumpAndSettle();

    router.go(AppRoutes.records);
    await tester.pumpAndSettle();
    expect(_pane(), findsOneWidget);
    expect(
      find.descendant(of: _pane(), matching: find.text(Copy.emptyHeadline)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _pane(), matching: find.text('Alpha')),
      findsNothing,
    );
  });

  testWidgets('at 1200 dp the body shows the open project, not a second list', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>['Alpha']);
    addTearDown(repo.dispose);
    await _pump(tester, width: 1200, repo: repo, projectId: 'project-1');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('route-project')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('route-projects')), findsNothing);
    expect(
      find.descendant(of: _pane(), matching: find.text('Alpha')),
      findsOneWidget,
    );
    expect(find.byType(AppListTile), findsOneWidget);
    expect(find.text(Copy.continueCapturing), findsOneWidget);
    expect(find.text(Copy.projectsCreate), findsNothing);
  });

  testWidgets('at 1200 dp with no projects the body keeps Create a project', (
    WidgetTester tester,
  ) async {
    await _pump(tester, width: 1200);
    await tester.pumpAndSettle();

    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(find.text(Copy.projectsCreate), findsWidgets);
    expect(
      find.descendant(
        of: _pane(),
        matching: find.text(Copy.projectsEmptyHeadline),
      ),
      findsOneWidget,
    );
  });

  testWidgets('search text and the open project survive 400 and 1200 dp', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>[
      'Alpha',
      'Beta',
    ]);
    addTearDown(repo.dispose);
    await _pump(tester, width: 400, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('route-project')), findsOneWidget);

    await _setWidth(tester, 1200);
    await tester.pumpAndSettle();
    expect(_pane(), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('route-project')), findsOneWidget);

    await tester.enterText(_paneSearch(), 'Alp');
    await tester.pump(AppConstants.interaction.debounce);
    expect(
      find.descendant(of: _pane(), matching: find.text('Beta')),
      findsNothing,
    );

    await _setWidth(tester, 400);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('route-project')), findsOneWidget);

    await _setWidth(tester, 1200);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_paneSearch()).controller?.text, 'Alp');
    expect(
      find.descendant(of: _pane(), matching: find.text('Beta')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('route-project')), findsOneWidget);
  });

  testWidgets(
    'the pane renders loading, error and offline through AsyncValueView',
    (WidgetTester tester) async {
      final StreamController<List<ProjectListRow>> pending =
          StreamController<List<ProjectListRow>>();
      addTearDown(pending.close);
      await _pump(
        tester,
        width: 1200,
        overrides: <Override>[
          projectListProvider.overrideWith((Ref _) => pending.stream),
        ],
      );
      await tester.pump();
      expect(
        find.descendant(of: _pane(), matching: find.byType(AppSkeleton)),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(
        tester,
        width: 1200,
        overrides: <Override>[
          projectListProvider.overrideWith(
            (Ref _) =>
                Stream<List<ProjectListRow>>.error(const NetworkFailure()),
          ),
        ],
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.descendant(of: _pane(), matching: find.byType(AppErrorState)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _pane(),
          matching: find.text(const NetworkFailure().message),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('the pane clips nothing at 200 percent text or in landscape', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>[
      'Alpha',
      'A very long project name that must wrap at two hundred percent',
    ]);
    addTearDown(repo.dispose);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, width: 1200, height: 800, repo: repo);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_pane(), findsOneWidget);

    await _setWidth(tester, 1200, height: 600);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_pane(), findsOneWidget);
  });

  testWidgets('an iPad-width portrait window still gets the pane', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>['Alpha']);
    addTearDown(repo.dispose);
    await _pump(tester, width: 1024, height: 1366, repo: repo);
    await tester.pumpAndSettle();
    expect(_pane(), findsOneWidget);
    expect(
      find.descendant(of: _pane(), matching: find.text('Alpha')),
      findsOneWidget,
    );
  });

  testWidgets('the pane search and rows mirror in RTL', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>['Alpha']);
    addTearDown(repo.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          networkOnlineOverride(),
          projectRepositoryProvider.overrideWith((Ref _) => repo),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: Sizes.listPane,
              height: 800,
              child: ProjectListView(filtered: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder tile = find.byType(AppListTile);
    final Finder title = find.descendant(
      of: tile,
      matching: find.text('Alpha'),
    );
    final Finder menu = find.descendant(
      of: tile,
      matching: find.byType(AppOverflowMenu),
    );
    expect(tester.getTopLeft(menu).dx, lessThan(tester.getTopLeft(title).dx));
  });

  testWidgets(
    'crossing 1024 dp moves the list into the pane without an empty flash',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = await _seedProjects(<String>[
        'Alpha',
        'Beta',
      ]);
      addTearDown(repo.dispose);
      await _pump(tester, width: 800, repo: repo);
      await tester.pumpAndSettle();
      expect(find.byType(AppListTile), findsNWidgets(2));
      expect(_pane(), findsNothing);

      await _setWidth(tester, 1200);
      expect(_pane(), findsOneWidget);
      expect(
        find.descendant(of: _pane(), matching: find.byType(AppListTile)),
        findsNWidgets(2),
      );
      expect(find.text(Copy.emptyHeadline), findsNothing);
    },
  );

  testWidgets(
    'Projects shows no badge at zero and the count at one, nine and 99+',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      for (final ({double width, double height}) size
          in <({double width, double height})>[
            (width: 400, height: 800),
            (width: 800, height: 400),
            (width: 800, height: 1200),
            (width: 1200, height: 800),
          ]) {
        await _pump(tester, width: size.width, height: size.height, repo: repo);
        await tester.pumpAndSettle();
        expect(find.byType(Badge), findsNothing);
        expect(_chromeFor(tester, size.width), findsOneWidget);
      }

      _ok(await repo.create(aProject(id: 'p1', name: 'One')));
      await _expectCountAtSizes(tester, repo, '1');

      for (int index = 2; index <= 9; index++) {
        _ok(await repo.create(aProject(id: 'p$index', name: 'Project $index')));
      }
      await _expectCountAtSizes(tester, repo, '9');

      for (int index = 10; index <= 100; index++) {
        _ok(await repo.create(aProject(id: 'p$index', name: 'Project $index')));
      }
      await _expectCountAtSizes(tester, repo, '99+');
      expect(find.text('100'), findsNothing);
    },
  );

  testWidgets(
    'creating, archiving, deleting and restoring update the Projects badge',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      await _pump(tester, width: 400, repo: repo);
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);

      _ok(await repo.create(aProject(id: 'live', name: 'Live')));
      await tester.pumpAndSettle();
      expect(_badgeLabel(tester), '1');

      _ok(await repo.create(aProject(id: 'second', name: 'Second')));
      await tester.pumpAndSettle();
      expect(_badgeLabel(tester), '2');

      _ok(await repo.setStatus('second', ProjectStatus.archived));
      await tester.pumpAndSettle();
      expect(_badgeLabel(tester), '1');

      _ok(await repo.setStatus('second', ProjectStatus.active));
      await tester.pumpAndSettle();
      expect(_badgeLabel(tester), '2');

      _ok(await repo.delete('second'));
      await tester.pumpAndSettle();
      expect(_badgeLabel(tester), '1');

      _ok(await repo.delete('live'));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
    },
  );

  testWidgets('Capture, Records and Settings never gain a badge', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>['Alpha']);
    addTearDown(repo.dispose);
    for (final double width in <double>[400, 800, 1200]) {
      await _pump(tester, width: width, repo: repo);
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('nav-icon-1')),
          matching: find.byType(Badge),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('nav-icon-2')),
          matching: find.byType(Badge),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('nav-icon-3')),
          matching: find.byType(Badge),
        ),
        findsNothing,
      );
    }
  });

  testWidgets(
    'the Projects badge meets 4.5:1 in light, dark, outdoor and on the inverted rail',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = await _seedProjects(<String>['Alpha']);
      addTearDown(repo.dispose);
      for (final AppThemeMode mode in <AppThemeMode>[
        AppThemeMode.light,
        AppThemeMode.dark,
        AppThemeMode.outdoor,
      ]) {
        await _pump(tester, width: 400, repo: repo, mode: mode);
        await tester.pumpAndSettle();
        _expectBadgeContrast(tester);
      }

      await _pump(tester, width: 800, repo: repo, mode: AppThemeMode.light);
      await tester.pumpAndSettle();
      expect(_railInverted(tester), isTrue);
      _expectBadgeContrast(tester, inverted: true);
    },
  );

  testWidgets('the Projects destination announces its count', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>[
      'Alpha',
      'Beta',
    ]);
    addTearDown(repo.dispose);
    await _pump(tester, width: 400, repo: repo);
    await tester.pumpAndSettle();
    _expectAnnouncesCount(tester, 2);

    _ok(await repo.create(aProject(id: 'third', name: 'Gamma')));
    await tester.pumpAndSettle();
    expect(_badgeLabel(tester), '3');
    _expectAnnouncesCount(tester, 3);

    await _setWidth(tester, 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(_badgeLabel(tester), '3');
    _expectAnnouncesCount(tester, 3);
  });

  testWidgets('the badge does not clip or push labels at 200 percent text', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    for (int index = 0; index < 12; index++) {
      _ok(await repo.create(aProject(id: 'p$index', name: 'Project $index')));
    }
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final double width in <double>[400, 800, 1200]) {
      await _pump(tester, width: width, repo: repo);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_shellLabel(tester, Copy.navProjects), findsOneWidget);
      expect(_shellLabel(tester, Copy.navCapture), findsOneWidget);
      expect(_badgeLabel(tester), '12');
    }
  });

  testWidgets('in RTL the badge sits at the icon end, not hard right', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = await _seedProjects(<String>['Alpha']);
    addTearDown(repo.dispose);
    tester.platformDispatcher.localeTestValue = const Locale('ar');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    for (final double width in <double>[400, 800]) {
      await _pump(tester, width: width, repo: repo);
      await tester.pumpAndSettle();
      final Badge badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.alignment, AlignmentDirectional.topEnd);
      final BuildContext iconContext = tester.element(
        find.byKey(const ValueKey<String>('nav-icon-0')),
      );
      if (Directionality.of(iconContext) == TextDirection.rtl) {
        expect(
          tester.getCenter(find.byType(Badge)).dx,
          lessThan(
            tester
                .getCenter(find.byKey(const ValueKey<String>('nav-icon-0')))
                .dx,
          ),
        );
      }
    }
  });
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required double width,
  double height = 800,
  String? projectId,
  FakeProjectRepository? repo,
  AppThemeMode? mode,
  List<Override> overrides = const <Override>[],
}) async {
  _bindWidth(tester, width, height: height);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[
        networkOnlineOverride(),
        if (repo != null)
          projectRepositoryProvider.overrideWith((Ref _) => repo),
        if (mode != null)
          themeModeProvider.overrideWith(
            () => ThemeModeController.withStore(
              TextStore.memory(<String, String>{
                AppConstants.preferences.themeMode: mode.name,
              }),
            ),
          ),
        ...overrides,
      ],
      child: const TaptureApp(),
    ),
  );
  await tester.pump();
  final BuildContext context = tester.element(find.byType(TaptureApp));
  final ProviderContainer container = ProviderScope.containerOf(context);
  if (projectId != null) {
    container.read(openProjectIdProvider.notifier).open(projectId);
    await tester.pumpAndSettle();
  }
  return container.read(routerProvider);
}

void _bindWidth(WidgetTester tester, double width, {double height = 800}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _setWidth(
  WidgetTester tester,
  double width, {
  double height = 800,
}) async {
  _bindWidth(tester, width, height: height);
  await tester.pump();
}

Finder _pane() => find.byKey(const ValueKey<String>('nav-pane'));

Finder _paneSearch() {
  return find.descendant(of: _pane(), matching: find.byType(TextField));
}

Finder _paneTitle(String label) {
  return find.descendant(of: _pane(), matching: find.text(label));
}

Future<FakeProjectRepository> _seedProjects(List<String> names) async {
  final FakeProjectRepository repo = FakeProjectRepository();
  for (int index = 0; index < names.length; index++) {
    _ok(
      await repo.create(
        aProject(
          id: 'project-${index + 1}',
          name: names[index],
          updatedAt: DateTime.utc(
            2026,
            9,
            17,
            8,
          ).subtract(Duration(minutes: index)),
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

Finder _shellLabel(WidgetTester tester, String label) {
  final Finder inBar = find.descendant(
    of: find.byKey(const ValueKey<String>('nav-bar')),
    matching: find.text(label),
  );
  if (inBar.evaluate().isNotEmpty) {
    return inBar;
  }
  return find.descendant(
    of: find.byKey(const ValueKey<String>('nav-rail')),
    matching: find.text(label),
  );
}

void _expectCaptureSize(WidgetTester tester) {
  expect(find.byKey(const ValueKey<String>('nav-icon-0')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-1')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-2')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-3')), findsOneWidget);

  final Icon capture = _navIcon(tester, 1);
  final Icon projects = _navIcon(tester, 0);
  expect(capture.size, Space.x8);
  expect(projects.size, Space.x6);
  expect(capture.size! > projects.size!, isTrue);
}

Icon _navIcon(WidgetTester tester, int index) {
  return tester.widget<Icon>(find.byKey(ValueKey<String>('nav-icon-$index')));
}

Color _accent(WidgetTester tester) {
  final BuildContext context = tester.element(find.byType(NavShell));
  return _railInverted(tester)
      ? AppColors.dark.primary
      : context.colors.primary;
}

Color _unselectedInk(WidgetTester tester) {
  final BuildContext context = tester.element(find.byType(NavShell));
  return _railInverted(tester)
      ? context.colors.surface
      : context.colors.onSurface;
}

bool _railInverted(WidgetTester tester) {
  if (find.byKey(const ValueKey<String>('nav-rail')).evaluate().isEmpty) {
    return false;
  }
  final BuildContext context = tester.element(find.byType(NavShell));
  final AppColors colors = context.colors;
  final bool outdoor =
      colors.surface == AppColors.outdoor.surface &&
      colors.onSurface == AppColors.outdoor.onSurface &&
      colors.outline == AppColors.outdoor.outline;
  return Theme.of(context).brightness == Brightness.light && !outdoor;
}

Finder _chromeFor(WidgetTester tester, double width) {
  if (width < 600) {
    return find.byKey(const ValueKey<String>('nav-bar'));
  }
  return find.byKey(const ValueKey<String>('nav-rail'));
}

Future<void> _expectCountAtSizes(
  WidgetTester tester,
  FakeProjectRepository repo,
  String label,
) async {
  for (final ({double width, double height}) size
      in <({double width, double height})>[
        (width: 400, height: 800),
        (width: 800, height: 400),
        (width: 800, height: 1200),
        (width: 1200, height: 800),
      ]) {
    await _pump(tester, width: size.width, height: size.height, repo: repo);
    await tester.pumpAndSettle();
    expect(_chromeFor(tester, size.width), findsOneWidget);
    expect(_badgeLabel(tester), label);
    expect(find.byType(Badge), findsOneWidget);
  }
}

String _badgeLabel(WidgetTester tester) {
  final Badge badge = tester.widget<Badge>(find.byType(Badge));
  final Text label = badge.label! as Text;
  return label.data!;
}

void _expectBadgeContrast(WidgetTester tester, {bool inverted = false}) {
  final Badge badge = tester.widget<Badge>(find.byType(Badge));
  final Color fill = badge.backgroundColor!;
  final Color ink = badge.textColor!;
  final AppColors expected = inverted
      ? AppColors.dark
      : tester.element(find.byType(NavShell)).colors;
  expect(fill, expected.primary);
  expect(ink, expected.onPrimary);
  expect(_contrast(ink, fill), greaterThanOrEqualTo(4.5));
}

void _expectAnnouncesCount(WidgetTester tester, int count) {
  final Semantics semantics = tester.widget<Semantics>(
    find.byKey(const ValueKey<String>('nav-count-live')),
  );
  expect(semantics.properties.label, Copy.navProjectsCount(count));
  expect(semantics.properties.liveRegion, isTrue);
}

double _contrast(Color a, Color b) {
  final double left = a.computeLuminance();
  final double right = b.computeLuminance();
  final double lighter = left > right ? left : right;
  final double darker = left > right ? right : left;
  return (lighter + 0.05) / (darker + 0.05);
}
