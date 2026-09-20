import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
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

  testWidgets(
    'the query matches an accent-folded name and ignores organisation',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _ok(await repo.create(aProject(id: 'p1', name: 'Café')));
      _ok(
        await repo.create(
          aProject(id: 'p2', name: 'Alpha').copyWith(organisation: 'Café Co'),
        ),
      );
      final ProviderContainer container = await _pump(tester, repo);

      container.read(projectListSearchQueryProvider.notifier).set('cafe');
      await tester.pump();
      expect(_names(container), <String>['Café']);
    },
  );

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
