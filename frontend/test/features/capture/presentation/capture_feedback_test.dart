import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' show AppDatabase;
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';
import 'package:tapture/features/context/context.dart'
    show contextRepositoryProvider;
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/projects/domain/project.dart';
import 'package:tapture/features/projects/domain/project_settings.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/presentation/capture_settings_screen.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';
import 'package:tapture/features/settings/presentation/operator_profile_screen.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/domain/template_row.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_context_repository.dart';
import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  testWidgets('operator loads from the shared database', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase.memory();
    addTearDown(database.close);
    await ensureDeviceProfile(database, deviceId: 'device-1');
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWith((Ref _) => database),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const OperatorProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorState), findsNothing);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('capture settings read the shared settings store', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase.memory();
    addTearDown(database.close);
    final SettingsStore store = await SettingsStore.open(
      db: database,
      deviceId: 'device-1',
      clock: const SystemClock(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          offlineStoreProvider.overrideWith((Ref _) => store),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const CaptureSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorState), findsNothing);
    expect(find.text(Copy.settingsAutoFillDates), findsOneWidget);
    await tester.tap(find.text(Copy.settingsAutoFillDates));
    await tester.pumpAndSettle();
    expect(store.read(SettingKeys.autoFillDates), isFalse);
  });

  testWidgets('the add sheet puts a library photo in the tray', (
    WidgetTester tester,
  ) async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final Uint8List image = Uint8List.fromList(<int>[1, 2, 3, 4]);
    await tester.pumpWidget(
      _scope(
        const CaptureScreen(projectId: 'p1'),
        extras: <Override>[
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          capturePersistenceProvider.overrideWith(
            (Ref ref) => CapturePersistenceImpl(
              photos: photos,
              store: TextStore.memory(),
            ),
          ),
          capturePhotoPickerProvider.overrideWith(
            (Ref _) => PhotoPicker.fake(
              photos: <Uint8List>[image],
              canTakePhoto: false,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Copy.captureAddPhoto));
    await tester.pumpAndSettle();
    expect(find.text(Copy.captureTakePhoto), findsNothing);
    await tester.tap(find.text(Copy.captureChoosePhoto));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('a caption can target one photo, the selection, and all', (
    WidgetTester tester,
  ) async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final TextStore store = TextStore.memory();
    await tester.pumpWidget(
      _scope(
        const CaptureScreen(projectId: 'p1'),
        extras: <Override>[
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          capturePersistenceProvider.overrideWith(
            (Ref ref) => CapturePersistenceImpl(photos: photos, store: store),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final CaptureController controller = ProviderScope.containerOf(
      tester.element(find.byType(CaptureScreen)),
    ).read(captureControllerProvider('p1').notifier);
    for (final String id in <String>['a', 'b', 'c']) {
      await controller.addPhoto(_draft(id));
    }
    await tester.pumpAndSettle();
    await tester.longPress(find.text('a').first);
    await tester.longPress(find.text('b').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('a').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Copy.capturePhotoCaption));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.captionScopeAll(3)));
    await tester.enterText(find.byType(TextField).last, 'lab');
    await tester.tap(find.text(Copy.captureSaved));
    await tester.pumpAndSettle();
    final CaptureSession session = ProviderScope.containerOf(
      tester.element(find.byType(CaptureScreen)),
    ).read(captureControllerProvider('p1'));
    expect(session.captions['a'], 'lab');
    expect(session.captions['b'], 'lab');
    expect(session.captions['c'], 'lab');
  });

  testWidgets('resume restores a stored session', (WidgetTester tester) async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final TextStore store = TextStore.memory();
    final CaptureSession saved = CaptureSession(
      id: 's1',
      projectId: 'p1',
      templateId: '',
      contextSnapshot: const <String, String>{},
      photos: <PhotoDraft>[_draft('kept')],
      captions: const <String, String>{'kept': 'note'},
    );
    await CapturePersistenceImpl(
      photos: photos,
      store: store,
    ).saveSession(saved);
    await tester.pumpWidget(
      _scope(
        const CaptureScreen(projectId: 'p1'),
        extras: <Override>[
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          capturePersistenceProvider.overrideWith(
            (Ref ref) => CapturePersistenceImpl(photos: photos, store: store),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.captureResume), findsOneWidget);
    await tester.tap(find.text(Copy.captureResume));
    await tester.pumpAndSettle();
    expect(find.text('kept'), findsWidgets);
  });

  testWidgets('crop keeps the source path and stores a derived copy', (
    WidgetTester tester,
  ) async {
    final PhotoDraft source = _draft('a');
    PhotoDraft? derived;
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoCropScreen(
          photo: source,
          bytes: _png,
          onCropped: (PhotoDraft next, Uint8List? png) {
            derived = next;
            expect(png, isNotNull);
          },
          onRevert: (_) {},
        ),
      ),
    );
    final TextButton button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, Copy.photoCrop),
    );
    await tester.runAsync(() async {
      button.onPressed!.call();
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    expect(source.relativePath, 'photos/a.jpg');
    expect(derived?.derivedFrom, 'a');
    expect(derived?.relativePath, isNot('photos/a.jpg'));
  });

  testWidgets('an empty site level draws no chip', (WidgetTester tester) async {
    final FakeContextRepository contexts = FakeContextRepository();
    addTearDown(contexts.dispose);
    await contexts.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'site', order: 0, label: 'Site'),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          contextRepositoryProvider.overrideWith((Ref _) => contexts),
        ],
        child: const MaterialApp(home: Scaffold(body: ContextBar())),
      ),
    );
    await tester.pump();
    ProviderScope.containerOf(
      tester.element(find.byType(ContextBar)),
    ).read(currentProjectProvider.notifier).open('p1');
    await tester.pumpAndSettle();
    expect(find.text('Site'), findsNothing);
  });

  testWidgets('manual choice with two templates shows the sheet first', (
    WidgetTester tester,
  ) async {
    final Project project = aProject(
      id: 'p1',
      name: 'Alpha',
    ).copyWith(settings: const ProjectSettings(templateChoice: 'manual'));
    await tester.pumpWidget(
      _scope(
        const CaptureScreen(projectId: 'p1'),
        extras: <Override>[
          currentProjectDetailsProvider.overrideWith((Ref _) => project),
          captureTemplatesProvider.overrideWith(
            (Ref _) => Stream<List<TemplateDef>>.value(<TemplateDef>[
              _template('t1', 'Computers'),
              _template('t2', 'Furniture'),
            ]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Computers'), findsOneWidget);
    expect(find.text('Furniture'), findsOneWidget);
  });
}

Widget _scope(Widget child, {List<Override> extras = const <Override>[]}) {
  return ProviderScope(
    overrides: extras,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

PhotoDraft _draft(String id) {
  return PhotoDraft(
    id: id,
    projectId: 'p1',
    relativePath: 'photos/$id.jpg',
    sha256: 'h$id',
    photoType: id,
  );
}

TemplateDef _template(String id, String name) {
  return TemplateDef(
    id: id,
    templateKey: id,
    name: name,
    version: 1,
    fields: const <FieldDef>[],
    identityFieldKeys: const <String>[],
    rows: const <TemplateRow>[],
    projectId: 'p1',
  );
}

final Uint8List _png = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
