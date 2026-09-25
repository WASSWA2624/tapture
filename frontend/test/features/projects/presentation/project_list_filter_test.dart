import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('an empty query leaves the watched rows unchanged', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(id: 'p1', name: 'Alpha')));
    _ok(await repo.create(aProject(id: 'p2', name: 'Beta')));
    final ProviderContainer container = await _pump(tester, repo);

    expect(_names(container), unorderedEquals(<String>['Alpha', 'Beta']));
  });

  testWidgets('the query accent-folds name, description, and organisation', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(id: 'p1', name: 'Café')));
    _ok(
      await repo.create(
        aProject(id: 'p2', name: 'Alpha').copyWith(organisation: 'Café Co'),
      ),
    );
    _ok(
      await repo.create(
        aProject(id: 'p3', name: 'Gamma').copyWith(description: 'Café survey'),
      ),
    );
    final ProviderContainer container = await _pump(tester, repo);

    container.read(projectListSearchQueryProvider.notifier).set('cafe');
    await tester.pump();
    expect(
      _names(container),
      unorderedEquals(<String>['Café', 'Alpha', 'Gamma']),
    );
  });

  testWidgets('status, pin, organisation, and search combine in one pass', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final DateTime pinnedAt = DateTime.utc(2026, 9, 23);
    _ok(
      await repo.create(
        aProject(
          id: 'p1',
          name: 'Alpha',
          pinnedAt: pinnedAt,
        ).copyWith(description: 'Northern café survey', organisation: 'Org A'),
      ),
    );
    _ok(
      await repo.create(
        aProject(
          id: 'p2',
          name: 'Beta',
          status: ProjectStatus.archived,
        ).copyWith(organisation: 'Org B'),
      ),
    );
    _ok(
      await repo.create(
        aProject(id: 'p3', name: 'Gamma').copyWith(organisation: 'Org A'),
      ),
    );
    final ProviderContainer container = await _pump(tester, repo);

    final ProjectListCriteria criteria = ProjectListCriteria(
      query: 'cafe',
      statuses: const <ProjectStatus>{
        ProjectStatus.active,
        ProjectStatus.archived,
      },
      pin: ProjectPinFilter.pinned,
      organisations: const <String>{'Org A'},
    );
    container.read(projectListCriteriaProvider.notifier).set(criteria);
    await tester.pump();

    expect(_names(container), <String>['Alpha']);
    expect(criteria.activeFilterCount, 3);
  });

  test('criteria snapshots defensively copy filter sets', () {
    final Set<ProjectStatus> statuses = <ProjectStatus>{ProjectStatus.active};
    final ProjectListCriteria criteria = ProjectListCriteria(
      statuses: statuses,
    );

    statuses.add(ProjectStatus.archived);

    expect(criteria.statuses, <ProjectStatus>{ProjectStatus.active});
    expect(
      () => criteria.statuses.add(ProjectStatus.archived),
      throwsUnsupportedError,
    );
  });

  testWidgets('a query that matches nothing yields an empty data value', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    final ProviderContainer container = await _pump(tester, repo);

    container.read(projectListSearchQueryProvider.notifier).set('zzzz');
    await tester.pump();
    expect(container.read(projectListFilteredProvider).asData?.value, isEmpty);
  });
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeProjectRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: const SizedBox.shrink(),
    ),
  );
  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(SizedBox)),
  );
  container.listen(
    projectListFilteredProvider,
    (
      AsyncValue<List<ProjectListRow>>? _,
      AsyncValue<List<ProjectListRow>> _,
    ) {},
  );
  await tester.pump();
  return container;
}

List<String> _names(ProviderContainer container) {
  return container
      .read(projectListFilteredProvider)
      .asData!
      .value
      .map((ProjectListRow row) => row.project.name)
      .toList();
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
