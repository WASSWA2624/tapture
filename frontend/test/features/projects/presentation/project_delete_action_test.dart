import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/projects/presentation/project_delete_action.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_stt_service.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('typed-name confirmation deletes and keeps the folder name', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedCounts('project-1', recordCount: 2);
    repo.seedFiles('project-1', files: 1);
    await _pump(tester, repo: repo);
    await tester.pump();

    await tester.tap(find.text(Copy.projectDelete));
    await tester.pump();

    expect(
      find.text(Copy.fieldLabelRequired(Copy.projectDeleteTypeName)),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Wrong');
    await tester.pump();
    await tester.tap(find.text(Copy.projectDelete).last);
    await tester.pump();
    expect(repo.stored.single.status, ProjectStatus.active);

    await tester.enterText(find.byType(TextField), 'Alpha');
    await tester.pump();
    await tester.tap(find.text(Copy.projectDelete).last);
    await tester.pump();

    expect(repo.stored.single.status, ProjectStatus.deleted);
    expect(repo.stored.single.folderName, 'test-project');
    expect(repo.tombstones, isNotEmpty);
    expect(repo.recycled, <String>['test-project']);
  });

  testWidgets('cancel leaves the project active', (WidgetTester tester) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();

    await tester.tap(find.text(Copy.projectDelete));
    await tester.pump();
    await tester.tap(find.text(Copy.cancel));
    await tester.pump();

    expect(repo.stored.single.status, ProjectStatus.active);
    expect(repo.tombstones, isEmpty);
    expect(repo.recycled, isEmpty);
  });

  testWidgets('export first closes the dialog without deleting', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, withExports: true);
    await tester.pump();

    await tester.tap(find.text(Copy.projectDelete));
    await tester.pump();
    await tester.tap(find.text(Copy.projectExportFirst));
    await tester.pump();
    await tester.pump();

    expect(repo.stored.single.status, ProjectStatus.active);
    expect(find.text('exports'), findsOneWidget);
  });

  testWidgets('the typed-name field offers no microphone', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, speech: FakeSttService());
    await tester.pump();

    await tester.tap(find.text(Copy.projectDelete));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('app-text-field-dictate')),
      findsNothing,
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeProjectRepository repo,
  bool withExports = false,
  FakeSttService? speech,
}) async {
  final Widget action = ProjectDeleteAction(project: aProject(name: 'Alpha'));
  final GoRouter? router = withExports
      ? GoRouter(
          initialLocation: '/',
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext _, GoRouterState _) {
                return Scaffold(body: action);
              },
            ),
            GoRoute(
              path: '/more/exports',
              builder: (BuildContext _, GoRouterState _) {
                return const Text('exports');
              },
            ),
          ],
        )
      : null;
  if (router != null) {
    addTearDown(router.dispose);
  }
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(),
        ),
      ],
      child: _withSpeech(
        speech,
        router == null
            ? MaterialApp(
                theme: buildTheme(brightness: Brightness.light),
                home: Scaffold(body: action),
              )
            : MaterialApp.router(
                theme: buildTheme(brightness: Brightness.light),
                routerConfig: router,
              ),
      ),
    ),
  );
}

Widget _withSpeech(FakeSttService? speech, Widget child) {
  if (speech == null) {
    return child;
  }
  return DictationScope(service: speech, languageTag: 'sw', child: child);
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
