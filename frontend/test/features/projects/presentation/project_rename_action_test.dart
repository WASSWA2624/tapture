import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/projects/presentation/project_rename_action.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('Save writes the name and leaves the folder', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final Project project = _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, project: project);

    await tester.tap(find.text(Copy.projectRename));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Omega');
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();

    expect(repo.stored.single.name, 'Omega');
    expect(repo.stored.single.folderName, 'test-project');
    expect(find.text(Copy.projectRenameTitle), findsNothing);
  });

  testWidgets('Cancel leaves the stored name', (WidgetTester tester) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final Project project = _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, project: project);

    await tester.tap(find.text(Copy.projectRename));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Omega');
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();

    expect(repo.stored.single.name, 'Alpha');
    expect(find.text(Copy.projectRenameTitle), findsNothing);
  });

  testWidgets('Save is disabled when the name is empty', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final Project project = _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, project: project);

    await tester.tap(find.text(Copy.projectRename));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    final AppButton save = tester.widget<AppButton>(
      find.widgetWithText(AppButton, Copy.save),
    );
    expect(save.onPressed, isNull);
    expect(repo.stored.single.name, 'Alpha');
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeProjectRepository repo,
  required Project project,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              return AppButton(
                label: Copy.projectRename,
                onPressed: () =>
                    ProjectRenameAction.open(context, ref, project),
              );
            },
          ),
        ),
      ),
    ),
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
