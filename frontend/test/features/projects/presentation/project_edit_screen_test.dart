import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/projects/presentation/project_edit_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_stt_service.dart';
import '../../../support/screen_matrix.dart';
import '../fakes/fake_project_repository.dart';

final Finder _mic = find.byKey(
  const ValueKey<String>('app-text-field-dictate'),
);

void main() {
  testWidgets('an untouched edit is quiet and clearing its name validates', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();
    expect(find.text(Copy.nameRequired), findsNothing);

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();
    expect(find.text(Copy.nameRequired), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'Beta');
    await tester.pump();
    expect(find.text(Copy.nameRequired), findsNothing);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    expect(find.text(Copy.nameRequired), findsWidgets);
    expect(repo.stored.single.name, 'Alpha');
  });

  testWidgets('valid edit clears a submitted name error and keeps other text', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'Keep this note');
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    expect(find.text(Copy.nameRequired), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Beta');
    await tester.pump();
    expect(find.text(Copy.nameRequired), findsNothing);
    expect(find.text('Keep this note'), findsOneWidget);
    expect(repo.stored.single.name, 'Alpha');
  });

  testWidgets('editing the name retains a storage error and all entered text', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository()
      ..updateFailure = const StorageFailure(
        message: 'Storage is unavailable.',
      );
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'Keep this note');
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    expect(find.text(Copy.nameRequired), findsWidgets);
    expect(find.text('Storage is unavailable.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Beta');
    await tester.pump();
    expect(find.text(Copy.nameRequired), findsNothing);
    expect(find.text('Storage is unavailable.'), findsOneWidget);
    expect(find.text('Keep this note'), findsOneWidget);
  });

  testWidgets('dictating a name clears its error without submitting', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    final FakeSttService speech = FakeSttService();
    await _pump(tester, repo: repo, speech: speech);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    expect(find.text(Copy.nameRequired), findsWidgets);
    final Finder microphone = find.byTooltip(
      Copy.dictateInto(Copy.projectName),
    );
    await tester.ensureVisible(microphone);
    await tester.pumpAndSettle();
    await tester.tap(microphone);
    await tester.pump();
    await speech.finish('Beta');
    await tester.pump();

    expect(find.text(Copy.nameRequired), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
    expect(repo.stored.single.name, 'Alpha');
  });

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'live edit-name validation fits ${cell.description}',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = cell.size;
        tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final FakeProjectRepository repo = FakeProjectRepository();
        addTearDown(repo.dispose);
        _ok(await repo.create(aProject(name: 'Alpha')));
        await _pump(tester, repo: repo, cell: cell);
        await tester.pump();
        await tester.enterText(find.byType(TextField).first, '');
        await tester.tap(find.byType(AppPrimaryAction));
        await tester.pump();
        await tester.enterText(find.byType(TextField).first, 'Beta');
        await tester.pumpAndSettle();
        expect(find.text(Copy.nameRequired), findsNothing);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.all(),
    );
  }
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

    expect(find.text(Copy.projectEditFormTitle), findsOneWidget);
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

  testWidgets('a save says so, and leaving afterwards asks nothing', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, push: true);
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Beta');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    await tester.pump();

    expect(find.text(Copy.projectSaved), findsOneWidget);
    expect(repo.stored.single.name, 'Beta');
    // A save returns to the page that opened the form, asking nothing.
    await tester.pumpAndSettle();
    expect(find.text(Copy.discardChangesTitle), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(find.text(Copy.projectEditFormTitle), findsNothing);
  });

  testWidgets('saving a project as archived keeps the form open', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text(Copy.projectStatusActive));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectStatusArchived).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();

    expect(repo.stored.single.status, ProjectStatus.archived);
    expect(find.text(Copy.projectEditEmptyHeadline), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Alpha',
    );
  });

  testWidgets('a second save starts from what the first one stored', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Beta');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();
    // The confirmation floats over the save bar; clear it for the next tap.
    ScaffoldMessenger.of(
      tester.element(find.byType(TextField).first),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await _pickPhoto(tester);
    await tester.enterText(find.byType(TextField).first, 'Gamma');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();

    expect(repo.stored.single.name, 'Gamma');
    expect(repo.stored.single.settings.coverPhoto, isNotNull);
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

  testWidgets('a photo is added and kept by Save, then removed', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await _pickPhoto(tester);
    expect(repo.stored.single.settings.coverPhoto, isNotNull);
    expect(
      find.byKey(const ValueKey<String>('project-photo-stored')),
      findsOneWidget,
    );

    // Save writes the stored settings, so the new photo stays.
    await tester.enterText(find.byType(TextField).first, 'Alpha Renamed');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();
    expect(repo.stored.single.name, 'Alpha Renamed');
    expect(repo.stored.single.settings.coverPhoto, isNotNull);

    final Finder remove = find.text(Copy.projectPhotoRemove);
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(repo.stored.single.settings.coverPhoto, isNull);
    expect(repo.coverFiles, hasLength(1));
    expect(find.text(Copy.projectPhotoAdd), findsOneWidget);
  });

  testWidgets('a photo that cannot be stored says so', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository()
      ..coverPhotoFailure = const StorageFailure(message: 'Disk is full.');
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await _pickPhoto(tester);
    expect(find.text('Disk is full.'), findsOneWidget);
    expect(repo.stored.single.settings.coverPhoto, isNull);
  });

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
  ScreenMatrix? cell,
}) async {
  const Widget screen = ProjectEditScreen(projectId: 'project-1');
  final Widget app = MaterialApp(
    theme: buildTheme(
      brightness: cell?.brightness ?? Brightness.light,
      outdoor: cell?.outdoor ?? false,
    ),
    home: push
        ? Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => screen,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
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
        photoPickerProvider.overrideWith(
          (Ref _) => PhotoPicker.fake(photos: <Uint8List>[_photoBytes]),
        ),
        photoThumbnailsProvider.overrideWith(
          (Ref _) => PhotoThumbnails.fake(const <String, String>{}),
        ),
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

final Uint8List _photoBytes = Uint8List.fromList(<int>[9, 8, 7]);

/// Picks the fake photo through the add-photo sheet.
Future<void> _pickPhoto(WidgetTester tester) async {
  final Finder add = find.text(Copy.projectPhotoAdd);
  await tester.ensureVisible(add);
  await tester.pumpAndSettle();
  await tester.tap(add);
  await tester.pumpAndSettle();
  await tester.tap(find.text(Copy.captureChoosePhoto));
  await tester.pumpAndSettle();
}
