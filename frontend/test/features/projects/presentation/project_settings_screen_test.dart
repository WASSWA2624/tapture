import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/projects/presentation/project_settings_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('a populated form states the app defaults', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();

    expect(find.text(Copy.projectSettingsTitle), findsOneWidget);
    expect(find.textContaining(Copy.projectAiEnabled), findsOneWidget);
    expect(find.textContaining(Copy.projectDoNotSendImages), findsOneWidget);
    expect(
      find.textContaining(Copy.projectAppDefault(Copy.projectOn)),
      findsWidgets,
    );
    expect(
      find.textContaining(Copy.projectAppDefault(Copy.projectOff)),
      findsWidgets,
    );
  });

  testWidgets('a dirty form prompts before leaving', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, push: true);
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '0.9');
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();

    expect(find.text(Copy.discardChangesTitle), findsOneWidget);
  });

  testWidgets('a failed save shows the failure on the form', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository()
      ..updateFailure = const StorageFailure(
        message: 'The project settings could not be saved.',
        recoveryAction: 'Try again.',
      );
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '0.9');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('The project settings could not be saved.'),
      findsOneWidget,
    );
    expect(repo.stored.single.settings.aiEnabled, isNull);
  });

  testWidgets('saving AI off and do-not-send-images on stops provider calls', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();

    await tester.tap(find.text(Copy.projectOff).first);
    await tester.pump();
    await tester.tap(find.text(Copy.projectOn).at(1));
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    await tester.pump();

    final ProjectSettings saved = repo.stored.single.settings;
    expect(saved.aiEnabled, isFalse);
    expect(saved.doNotSendImages, isTrue);
    expect(saved.allowsProviderCalls(builtInProjectSettingsDefaults), isFalse);
    expect(saved.allowsImageEgress(builtInProjectSettingsDefaults), isFalse);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeProjectRepository repo,
  bool push = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const Widget screen = ProjectSettingsScreen();
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(
            stored: <String, Object?>{
              SettingKeys.openProjectId.name: 'project-1',
            },
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: push
            ? Builder(
                builder: (BuildContext context) {
                  return TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext _) => screen,
                        ),
                      );
                    },
                    child: const Text('open'),
                  );
                },
              )
            : screen,
      ),
    ),
  );
  await tester.pump();
  if (push) {
    await tester.tap(find.text('open'));
    await tester.pump();
  }
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
