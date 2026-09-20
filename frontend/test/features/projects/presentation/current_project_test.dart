import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  test('restores a persisted id when the project still exists', () async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject()));
    final SettingsStore store = SettingsStore.fake(
      stored: <String, Object?>{SettingKeys.openProjectId.name: 'project-1'},
    );
    final ProviderContainer container = _container(repo: repo, store: store);
    addTearDown(container.dispose);

    expect(container.read(currentProjectProvider), 'project-1');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentProjectProvider), 'project-1');
    expect(
      container.read(currentProjectProvider.notifier).consumeLaunchRestore(),
      'project-1',
    );
    expect(
      container.read(currentProjectProvider.notifier).consumeLaunchRestore(),
      isNull,
    );
  });

  test('clears an unresolvable persisted id', () async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final SettingsStore store = SettingsStore.fake(
      stored: <String, Object?>{SettingKeys.openProjectId.name: 'gone'},
    );
    final ProviderContainer container = _container(repo: repo, store: store);
    addTearDown(container.dispose);

    expect(container.read(currentProjectProvider), 'gone');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentProjectProvider), isNull);
    expect(store.read(SettingKeys.openProjectId), isNull);
    expect(
      container.read(currentProjectProvider.notifier).consumeLaunchRestore(),
      isNull,
    );
  });

  test(
    'opening a row persists the id and resumes a carried destination',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _ok(await repo.create(aProject()));
      final SettingsStore store = SettingsStore.fake();
      final ProviderContainer container = _container(repo: repo, store: store);
      addTearDown(container.dispose);

      container.read(currentProjectProvider.notifier).open('project-1');
      await Future<void>.delayed(Duration.zero);
      expect(container.read(currentProjectProvider), 'project-1');
      expect(store.read(SettingKeys.openProjectId), 'project-1');

      final GoRouter router = container.read(routerProvider);
      final Uri intended = Uri(
        path: AppRoutes.projects,
        queryParameters: <String, String>{
          AppRoutes.fromQuery: AppRoutes.capture('project-1'),
        },
      );
      final GoRouterState state = GoRouterState(
        router.configuration,
        uri: intended,
        matchedLocation: AppRoutes.projects,
        fullPath: AppRoutes.projects,
        pathParameters: const <String, String>{},
        pageKey: const ValueKey<String>('projects'),
      );

      String? to;
      for (final RouteGuard guard in appGuards()) {
        to = guard(state, _ref(container));
        if (to != null) {
          break;
        }
      }
      expect(to, AppRoutes.capture('project-1'));
    },
  );

  test(
    'projectNavCount counts active rows from the existing list watch',
    () async {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _ok(await repo.create(aProject(id: 'active', name: 'Active')));
      _ok(
        await repo.create(
          aProject(
            id: 'archived',
            name: 'Archived',
            status: ProjectStatus.archived,
          ),
        ),
      );
      final ProviderContainer container = _container(
        repo: repo,
        store: SettingsStore.fake(),
      );
      addTearDown(container.dispose);
      container.listen(projectListProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(projectNavCountProvider), 1);

      container.read(projectListShowArchivedProvider.notifier).set(true);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(projectNavCountProvider), 1);

      _ok(await repo.setStatus('archived', ProjectStatus.active));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(projectNavCountProvider), 2);
    },
  );
}

ProviderContainer _container({
  required FakeProjectRepository repo,
  required SettingsStore store,
}) {
  return ProviderContainer(
    overrides: <Override>[
      projectRepositoryProvider.overrideWith((Ref _) => repo),
      projectSettingsStoreProvider.overrideWith((Ref _) => store),
    ],
  );
}

Ref _ref(ProviderContainer container) {
  late Ref captured;
  container.read(
    Provider<int>((Ref ref) {
      captured = ref;
      return 0;
    }),
  );
  return captured;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
