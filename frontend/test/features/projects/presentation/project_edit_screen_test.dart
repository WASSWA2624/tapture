import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/projects/presentation/project_edit_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_stt_service.dart';
import '../fakes/fake_project_repository.dart';

final Finder _mic = find.byKey(
  const ValueKey<String>('app-text-field-dictate'),
);

void main() {
  testWidgets('a populated form shows the open project', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(
      await repo.create(
        aProject(
          name: 'Alpha',
        ).copyWith(description: 'A site note', organisation: 'City works'),
      ),
    );
    await _pump(tester, repo: repo);
    await tester.pump();

    expect(find.text(Copy.projectEditTitle), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Alpha',
    );
    expect(find.text(Copy.projectStatusActive), findsOneWidget);
  });

  testWidgets('a dirty form prompts before leaving', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, push: true);
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Beta');
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
        message: 'The project could not be saved on this device.',
        recoveryAction: 'Try again.',
      );
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Beta');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('The project could not be saved on this device.'),
      findsOneWidget,
    );
    expect(repo.stored.single.name, 'Alpha');
    expect(repo.stored.single.folderName, 'test-project');
  });

  testWidgets('a rename writes the name and leaves folderName unchanged', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Alpha Renamed');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    await tester.pump();

    final Project saved = repo.stored.single;
    expect(saved.name, 'Alpha Renamed');
    expect(saved.folderName, 'test-project');
  });

  testWidgets(
    'Name, Description and Organisation offer a labelled microphone',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _ok(await repo.create(aProject(name: 'Alpha')));
      await _pump(tester, repo: repo, speech: FakeSttService());
      await tester.pump();

      expect(_mic, findsNWidgets(3));
      expect(
        find.byTooltip(Copy.dictateInto(Copy.projectName)),
        findsOneWidget,
      );
      expect(
        find.byTooltip(Copy.dictateInto(Copy.projectDescription)),
        findsOneWidget,
      );
      expect(
        find.byTooltip(Copy.dictateInto(Copy.projectOrganisation)),
        findsOneWidget,
      );
      expect(_mic, meetsTapTarget());
    },
  );

  testWidgets('Project details fits at 360 dp and 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, speech: FakeSttService());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(_mic, findsNWidgets(3));
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeProjectRepository repo,
  bool push = false,
  FakeSttService? speech,
}) async {
  const Widget screen = ProjectEditScreen();
  final Widget app = MaterialApp(
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
  );
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
      child: speech == null
          ? app
          : DictationScope(service: speech, languageTag: 'sw', child: app),
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
