import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/gallery/widget_gallery_screen.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/settings/presentation/appearance_settings_screen.dart';

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
    expect(AppRoutes.record('cd'), '/records/cd');
    expect(AppRoutes.records, '/records');
    expect(AppRoutes.more, '/more');
    expect(AppRoutes.templates, '/templates');
    expect(AppRoutes.queue, '/queue');
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

    await _go(tester, router, AppRoutes.capture('p1'));
    expect(find.byKey(const ValueKey<String>('route-capture')), findsOneWidget);

    await _go(tester, router, AppRoutes.record('r1'));
    expect(find.byKey(const ValueKey<String>('route-record')), findsOneWidget);

    await _go(tester, router, AppRoutes.templates);
    expect(
      find.byKey(const ValueKey<String>('route-templates')),
      findsOneWidget,
    );

    await _go(tester, router, AppRoutes.queue);
    expect(find.byKey(const ValueKey<String>('route-queue')), findsOneWidget);

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
}

Future<GoRouter> _pump(WidgetTester tester, {String? projectId}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [networkOnlineOverride()],
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
