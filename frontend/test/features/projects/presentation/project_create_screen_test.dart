import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/projects/presentation/project_create_screen.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/fakes/fake_stt_service.dart';
import '../fakes/fake_project_repository.dart';

final Finder _mic = find.byKey(
  const ValueKey<String>('app-text-field-dictate'),
);

void main() {
  testWidgets('an empty name fails validation and writes nothing', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    await _pump(tester, repo: repo);

    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(find.text(Copy.nameRequired), findsWidgets);
    expect(repo.count, 0);
  });

  testWidgets('a failed create shows the failure on the form', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository()
      ..createFailure = const StorageFailure(
        message: 'The project folder could not be created on this device.',
        recoveryAction: 'Free space or allow storage access, then try again.',
      );
    addTearDown(repo.dispose);
    await _pump(tester, repo: repo);

    await tester.enterText(find.byType(TextField).first, 'Alpha');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(
      find.text('The project folder could not be created on this device.'),
      findsOneWidget,
    );
    expect(repo.count, 0);
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(ProjectCreateScreen)),
      ).read(currentProjectProvider),
      isNull,
    );
  });

  testWidgets('a successful create opens the new project', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    await _pump(tester, repo: repo);

    await tester.enterText(find.byType(TextField).first, 'Alpha');
    await tester.enterText(find.byType(TextField).at(1), 'A site note');
    await tester.enterText(find.byType(TextField).at(2), 'City works');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(repo.count, 1);
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(ProjectCreateScreen)),
      ).read(currentProjectProvider),
      'created-1',
    );
  });

  testWidgets('duplicate prefills the suggested name', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    await _pump(
      tester,
      repo: repo,
      sourceId: 'source-1',
      initialName: Copy.projectCopyName('Alpha'),
    );

    expect(find.text(Copy.projectDuplicateTitle), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      Copy.projectCopyName('Alpha'),
    );
  });

  testWidgets(
    'Name, Description and Organisation offer a labelled microphone',
    (WidgetTester tester) async {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      await _pump(tester, repo: repo, speech: FakeSttService());

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

  testWidgets('dictating into Name inserts the words and does not submit', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final FakeSttService speech = FakeSttService();
    await _pump(tester, repo: repo, speech: speech);

    await tester.tap(find.byTooltip(Copy.dictateInto(Copy.projectName)));
    await tester.pump();
    await speech.finish('Alpha');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Alpha',
    );
    expect(repo.count, 0);
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(ProjectCreateScreen)),
      ).read(currentProjectProvider),
      isNull,
    );
  });

  testWidgets('New project fits at 360 dp and 200 percent text', (
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
    await _pump(tester, repo: repo, speech: FakeSttService());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(_mic, findsNWidgets(3));
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeProjectRepository repo,
  String? sourceId,
  String? initialName,
  FakeSttService? speech,
}) async {
  final Widget app = MaterialApp(
    theme: buildTheme(brightness: Brightness.light),
    home: ProjectCreateScreen(sourceId: sourceId, initialName: initialName),
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: speech == null
          ? app
          : DictationScope(service: speech, languageTag: 'sw', child: app),
    ),
  );
  await tester.pump();
}
