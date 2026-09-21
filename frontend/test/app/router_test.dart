import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/gallery/widget_gallery_screen.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/presentation/appearance_settings_screen.dart';
import 'package:tapture/features/settings/presentation/storage_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  test('AppRoutes helpers are the declared paths', () {
    expect(AppRoutes.projects, '/projects');
    expect(AppRoutes.lock, '/lock');
    expect(AppRoutes.project('ab'), '/projects/ab');
    expect(AppRoutes.projectCreate, '/projects/new');
    expect(
      AppRoutes.projectCreateFrom(sourceId: 'p1', name: 'Alpha (copy)'),
      contains('source=p1'),
    );
    expect(AppRoutes.capture('ab'), '/projects/ab/capture');
    expect(AppRoutes.projectEdit('ab'), '/projects/ab/edit');
    expect(AppRoutes.projectSettings('ab'), '/projects/ab/settings');
    expect(AppRoutes.record('cd'), '/records/cd');
    expect(AppRoutes.records, '/records');
    expect(AppRoutes.more, '/more');
    expect(AppRoutes.templates, '/more/templates');
    expect(AppRoutes.templateCreate, '/more/templates/new');
    expect(AppRoutes.templateLibrary, '/more/templates/library');
    expect(AppRoutes.template('ab'), '/more/templates/ab');
    expect(AppRoutes.templateExport('ab'), '/more/templates/ab/export');
    expect(
      AppRoutes.templateFieldCreate('ab'),
      '/more/templates/ab/fields/new',
    );
    expect(
      AppRoutes.templateField('ab', 'serial'),
      '/more/templates/ab/fields/serial',
    );
    expect(AppRoutes.templateAliases('ab'), '/more/templates/ab/aliases');
    expect(AppRoutes.templateChecklist('ab'), '/more/templates/ab/checklist');
    expect(AppRoutes.templateDetection('ab'), '/more/templates/ab/detection');
    expect(
      AppRoutes.captureRow(projectId: 'ab', templateId: 't1', rowId: 'm-1'),
      '/projects/ab/capture?template=t1&row=m-1',
    );
    expect(AppRoutes.queue, '/more/queue');
    expect(AppRoutes.exports, '/more/exports');
    expect(AppRoutes.projectRecords('ab'), '/projects/ab/records');
    expect(AppRoutes.projectQueue('ab'), '/projects/ab/queue');
    expect(AppRoutes.projectExports('ab'), '/projects/ab/exports');
    expect(
      AppRoutes.recordsFiltered(AppRoutes.reviewFilter),
      '/records?filter=needsReview',
    );
    expect(
      AppRoutes.queueFiltered(AppRoutes.processFilter),
      '/more/queue?filter=queued',
    );
    expect(
      AppRoutes.exportsFiltered(AppRoutes.shareFilter),
      '/more/exports?filter=share',
    );
    expect(
      AppRoutes.projectRecordsFiltered('ab', AppRoutes.reviewFilter),
      '/projects/ab/records?filter=needsReview',
    );
    expect(
      AppRoutes.projectQueueFiltered('ab', AppRoutes.processFilter),
      '/projects/ab/queue?filter=queued',
    );
    expect(
      AppRoutes.projectExportsFiltered('ab', AppRoutes.shareFilter),
      '/projects/ab/exports?filter=share',
    );
    expect(AppRoutes.settingsOperator, '/more/operator');
    expect(AppRoutes.settingsCapture, '/more/capture');
    expect(AppRoutes.settingsAi, '/more/ai');
    expect(AppRoutes.settingsLanguage, '/more/language');
    expect(AppRoutes.settingsAppearance, '/more/appearance');
    expect(AppRoutes.settingsStorage, '/more/storage');
    expect(AppRoutes.settingsFiles, '/more/files');
    expect(AppRoutes.settingsSecurity, '/more/security');
    expect(AppRoutes.settingsAbout, '/more/about');
  });

  test('no screen concatenates a path string', () {
    final List<String> offenders = <String>[];
    for (final File file in _dartFiles(Directory('lib'))) {
      final String path = file.path.replaceAll(r'\', '/');
      if (path.endsWith('/app/router.dart')) {
        continue;
      }
      if (path.endsWith('/app/route_guards.dart')) {
        continue;
      }
      final String source = file.readAsStringSync();
      if (source.contains("'/projects/") ||
          source.contains('"/projects/') ||
          source.contains("'/records/") ||
          source.contains('"/records/')) {
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join(', '));
  });

  testWidgets('every declared route resolves', (WidgetTester tester) async {
    final GoRouter router = await _pump(tester, projectId: 'p1');

    await _go(tester, router, AppRoutes.projects);
    expect(
      find.byKey(const ValueKey<String>('route-projects')),
      findsOneWidget,
    );

    router.go(AppRoutes.projectCreate);
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('route-project-create')),
      findsOneWidget,
    );

    await _go(tester, router, '/');
    expect(
      find.byKey(const ValueKey<String>('route-projects')),
      findsOneWidget,
    );

    await _go(tester, router, AppRoutes.project('p1'));
    expect(find.byKey(const ValueKey<String>('route-project')), findsOneWidget);

    router.go(AppRoutes.projectEdit('p1'));
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('route-project-edit')),
      findsOneWidget,
    );

    router.go(AppRoutes.projectSettings('p1'));
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('route-project-settings')),
      findsOneWidget,
    );

    router.go(AppRoutes.project('p1'));
    await tester.pump();
    await tester.pump();

    await _go(tester, router, AppRoutes.capture('p1'));
    expect(find.byKey(const ValueKey<String>('route-capture')), findsOneWidget);

    await _go(tester, router, AppRoutes.record('r1'));
    expect(find.byKey(const ValueKey<String>('route-record')), findsOneWidget);

    await _go(tester, router, AppRoutes.templates);
    expect(
      find.byKey(const ValueKey<String>('route-templates')),
      findsOneWidget,
    );

    await _go(tester, router, AppRoutes.templateCreate);
    expect(
      find.byKey(const ValueKey<String>('route-template-create')),
      findsOneWidget,
    );

    await _go(tester, router, AppRoutes.templateLibrary);
    expect(
      find.byKey(const ValueKey<String>('route-template-library')),
      findsOneWidget,
    );

    await _go(tester, router, AppRoutes.template('t1'));
    expect(
      find.byKey(const ValueKey<String>('route-template-fields')),
      findsOneWidget,
    );

    await _go(tester, router, AppRoutes.queue);
    expect(find.byKey(const ValueKey<String>('route-queue')), findsOneWidget);

    await _go(tester, router, AppRoutes.exports);
    expect(find.byKey(const ValueKey<String>('route-exports')), findsOneWidget);

    await _go(
      tester,
      router,
      AppRoutes.projectRecordsFiltered('p1', AppRoutes.reviewFilter),
    );
    expect(router.state.uri.path, AppRoutes.projectRecords('p1'));
    expect(
      router.state.uri.queryParameters[AppRoutes.filterQuery],
      AppRoutes.reviewFilter,
    );
    expect(find.byKey(const ValueKey<String>('route-records')), findsWidgets);

    await _go(tester, router, AppRoutes.more);
    expect(find.text(Copy.operatorProfileTitle), findsOneWidget);
    expect(find.text(Copy.settingsAboutTitle), findsOneWidget);

    await _go(tester, router, AppRoutes.settingsAppearance);
    expect(find.byType(AppearanceSettingsScreen), findsOneWidget);

    router.go(WidgetGalleryScreen.route);
    await tester.pump();
    await tester.pump();
    expect(find.byType(WidgetGalleryScreen), findsOneWidget);
  });

  testWidgets('legacy queue, exports and templates paths redirect', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester, projectId: 'p1');

    await _go(tester, router, '/queue?filter=queued');
    expect(router.state.uri.path, AppRoutes.queue);
    expect(
      router.state.uri.queryParameters[AppRoutes.filterQuery],
      AppRoutes.processFilter,
    );
    expect(find.byKey(const ValueKey<String>('route-queue')), findsOneWidget);

    await _go(tester, router, '/exports?filter=share');
    expect(router.state.uri.path, AppRoutes.exports);
    expect(
      router.state.uri.queryParameters[AppRoutes.filterQuery],
      AppRoutes.shareFilter,
    );
    expect(find.byKey(const ValueKey<String>('route-exports')), findsOneWidget);

    await _go(tester, router, '/templates');
    expect(router.state.uri.path, AppRoutes.templates);
    expect(
      find.byKey(const ValueKey<String>('route-templates')),
      findsOneWidget,
    );

    await _go(tester, router, '/templates/library');
    expect(router.state.uri.path, AppRoutes.templateLibrary);
    expect(
      find.byKey(const ValueKey<String>('route-template-library')),
      findsOneWidget,
    );
  });

  testWidgets('queue, exports and templates keep Settings beneath them', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester);

    await _go(tester, router, AppRoutes.queue);
    expect(find.byKey(const ValueKey<String>('route-queue')), findsOneWidget);
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.more);
    expect(find.text(Copy.operatorProfileTitle), findsOneWidget);

    await _go(tester, router, AppRoutes.exports);
    expect(find.byKey(const ValueKey<String>('route-exports')), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.more);
    expect(find.text(Copy.operatorProfileTitle), findsOneWidget);

    await _go(tester, router, AppRoutes.templates);
    expect(
      find.byKey(const ValueKey<String>('route-templates')),
      findsOneWidget,
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.more);
    expect(find.text(Copy.operatorProfileTitle), findsOneWidget);
  });

  testWidgets(
    'a project-scoped list path with no open project diverts and resumes',
    (WidgetTester tester) async {
      final GoRouter router = await _pump(tester);
      final String intended = AppRoutes.projectRecordsFiltered(
        'p1',
        AppRoutes.reviewFilter,
      );

      await _go(tester, router, intended);
      expect(
        find.byKey(const ValueKey<String>('route-projects')),
        findsOneWidget,
      );
      expect(router.state.uri.path, AppRoutes.projects);
      expect(router.state.uri.queryParameters[AppRoutes.fromQuery], intended);

      final BuildContext context = tester.element(find.byType(TaptureApp));
      ProviderScope.containerOf(
        context,
      ).read(openProjectIdProvider.notifier).open('p1');
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.projectRecords('p1'));
      expect(
        router.state.uri.queryParameters[AppRoutes.filterQuery],
        AppRoutes.reviewFilter,
      );
      expect(find.byKey(const ValueKey<String>('route-records')), findsWidgets);
    },
  );

  testWidgets('a record deep link opens it directly', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester);
    await _go(tester, router, AppRoutes.record('r1'));
    expect(find.byKey(const ValueKey<String>('route-record')), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.record('r1'));
  });

  testWidgets('an unknown path renders the shared error state', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester);
    await _go(tester, router, '/no-such-page');
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.textContaining('no-such-page'), findsOneWidget);

    await tester.tap(find.text(Copy.tryAgain));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('route-projects')),
      findsOneWidget,
    );
    expect(router.state.uri.path, AppRoutes.projects);
  });

  testWidgets('a stored internal location is the first route', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake(
      stored: <String, Object?>{
        SettingKeys.lastLocation.name: AppRoutes.settingsStorage,
      },
    );
    final GoRouter router = await _pump(
      tester,
      store: store,
      overrides: <Override>[storageSettingsOverride(cacheBytes: 0)],
    );
    await tester.pump();
    expect(router.state.uri.path, AppRoutes.settingsStorage);
  });

  testWidgets('a stored records filter is the first route', (
    WidgetTester tester,
  ) async {
    final String location = AppRoutes.recordsFiltered(AppRoutes.reviewFilter);
    final SettingsStore store = SettingsStore.fake(
      stored: <String, Object?>{SettingKeys.lastLocation.name: location},
    );
    final GoRouter router = await _pump(tester, store: store);
    await tester.pump();
    expect(router.state.uri.path, AppRoutes.records);
    expect(
      router.state.uri.queryParameters[AppRoutes.filterQuery],
      AppRoutes.reviewFilter,
    );
  });

  testWidgets('https and lock are ignored at launch', (
    WidgetTester tester,
  ) async {
    for (final String stored in <String>[
      'https://example.com',
      AppRoutes.lock,
    ]) {
      final SettingsStore store = SettingsStore.fake(
        stored: <String, Object?>{SettingKeys.lastLocation.name: stored},
      );
      final GoRouter router = await _pump(tester, store: store);
      await tester.pump();
      expect(router.state.uri.path, AppRoutes.projects);
    }
  });

  testWidgets('an empty last location opens projects', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester, store: SettingsStore.fake());
    await tester.pump();
    expect(router.state.uri.path, AppRoutes.projects);
  });

  testWidgets(
    'a stored project route whose project is missing lands on projects',
    (WidgetTester tester) async {
      final SettingsStore store = SettingsStore.fake(
        stored: <String, Object?>{
          SettingKeys.lastLocation.name: AppRoutes.project('missing'),
        },
      );
      final GoRouter router = await _pump(tester, store: store);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.projects);
    },
  );

  testWidgets('navigation persists the last internal location and skips lock', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake();
    final GoRouter router = await _pump(tester, store: store);
    await tester.pump();

    await _go(tester, router, AppRoutes.more);
    expect(store.read(SettingKeys.lastLocation), AppRoutes.more);

    await _go(
      tester,
      router,
      AppRoutes.recordsFiltered(AppRoutes.reviewFilter),
    );
    expect(
      store.read(SettingKeys.lastLocation),
      AppRoutes.recordsFiltered(AppRoutes.reviewFilter),
    );

    await _go(tester, router, AppRoutes.lock);
    expect(router.state.uri.path, AppRoutes.lock);
    expect(
      store.read(SettingKeys.lastLocation),
      AppRoutes.recordsFiltered(AppRoutes.reviewFilter),
    );
  });
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  String? projectId,
  SettingsStore? store,
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        networkOnlineOverride(),
        if (store != null)
          projectSettingsStoreProvider.overrideWith((Ref _) => store),
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

Future<void> _go(WidgetTester tester, GoRouter router, String location) async {
  router.go(location);
  await tester.pumpAndSettle();
}

List<File> _dartFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'))
      .toList();
}
