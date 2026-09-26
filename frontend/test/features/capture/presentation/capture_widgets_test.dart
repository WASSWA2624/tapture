import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/audio_recorder.dart';
import 'package:tapture/features/capture/presentation/barcode_continuous_mode.dart';
import 'package:tapture/features/capture/presentation/barcode_scanner_screen.dart';
import 'package:tapture/features/capture/presentation/camera_controls.dart';
import 'package:tapture/features/capture/presentation/camera_permission_gate.dart';
import 'package:tapture/features/capture/presentation/camera_view.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_recovery_prompt.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/capture/presentation/capture_storage_guard.dart';
import 'package:tapture/features/capture/presentation/document_mode.dart';
import 'package:tapture/features/capture/presentation/document_picker.dart';
import 'package:tapture/features/capture/presentation/gallery_picker.dart';
import 'package:tapture/features/capture/presentation/inline_fields_section.dart';
import 'package:tapture/features/capture/presentation/mic_permission_gate.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';
import 'package:tapture/features/capture/presentation/photo_multi_select.dart';
import 'package:tapture/features/capture/presentation/photo_reorder.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/photo_type_sheet.dart';
import 'package:tapture/features/capture/presentation/photo_viewer_screen.dart';
import 'package:tapture/features/capture/presentation/rapid_mode_screen.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/capture/presentation/voice_input_button.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_photo_repository.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../../templates/fakes/fake_template_repository.dart';

AppIconButton _icon(WidgetTester tester, String tooltip) {
  return tester.widget<AppIconButton>(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(AppIconButton),
    ),
  );
}

Widget wrap(Widget child, {List<Override> overrides = const <Override>[]}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

PhotoDraft draft(String id, {String type = 'other', int order = 0}) {
  return PhotoDraft(
    id: id,
    projectId: 'p1',
    relativePath: 'photos/$id.jpg',
    sha256: 'h$id',
    photoType: type,
    sortOrder: order,
  );
}

void main() {
  testWidgets('recording pauses when the app is interrupted', (
    WidgetTester tester,
  ) async {
    final AudioRecorderService recorder = AudioRecorderService.fake(
      tick: const Duration(seconds: 1),
    );
    await tester.pumpWidget(
      wrap(
        AudioRecorder(
          recorder: recorder,
          relativePath: 'audio/interrupted.wav',
        ),
      ),
    );

    await recorder.start('audio/interrupted.wav');
    await tester.pump();
    expect(find.text(Copy.capturePauseAudio), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.scheduleForcedFrame();
    await tester.pump();
    expect(find.text(Copy.audioRecorderStatus('paused', 0)), findsOneWidget);
    expect(find.text(Copy.captureStopAudio), findsOneWidget);
    expect(find.text(Copy.captureStopAudio), findsOneWidget);

    await recorder.stop();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('capture_screen compact medium evidence optional', (
    WidgetTester tester,
  ) async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    await tester.pumpWidget(
      wrap(
        const CaptureScreen(projectId: 'p1'),
        overrides: <Override>[
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          capturePersistenceProvider.overrideWith(
            (Ref ref) => CapturePersistenceImpl(
              photos: photos,
              store: TextStore.memory(),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.captureSaveRaw), findsOneWidget);
    expect(find.text(Copy.captureSaveAndAnalyse), findsOneWidget);
  });

  testWidgets('capture actions stay disabled until a project is chosen', (
    WidgetTester tester,
  ) async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    await projects.create(aProject(id: 'p1', name: 'Alpha'));
    await projects.create(aProject(id: 'p2', name: 'Beta'));
    await templates.save(aTemplate(id: 't1', name: 'Assets', projectId: 'p1'));
    await tester.pumpWidget(
      wrap(
        const CaptureScreen(projectId: ''),
        overrides: <Override>[
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          projectRepositoryProvider.overrideWith((Ref _) => projects),
          templateRepositoryProvider.overrideWith((Ref _) => templates),
          capturePersistenceProvider.overrideWith(
            (Ref ref) => CapturePersistenceImpl(
              photos: photos,
              store: TextStore.memory(),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.captureChooseProject), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('capture-project-field')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('capture-project-field')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(
      tester
          .widget<AppButton>(
            find.widgetWithText(AppButton, Copy.captureSaveRaw),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<AppPrimaryAction>(find.byType(AppPrimaryAction)).onPressed,
      isNull,
    );
    expect(_addPhotoIcon, findsNothing);
    expect(_icon(tester, Copy.captureRecordAudio).onPressed, isNull);

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(find.text(Copy.captureChooseProject), findsNothing);
    expect(find.text('Assets'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.widgetWithText(AppButton, Copy.captureSaveRaw),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppPrimaryAction>(find.byType(AppPrimaryAction)).onPressed,
      isNotNull,
    );
    expect(_addPhotoIcon, findsOneWidget);
    expect(_icon(tester, Copy.captureRecordAudio).onPressed, isNotNull);
  });

  group('capture layout', () {
    Future<void> pumpReady(
      WidgetTester tester, {
      required Size size,
      double textScale = 1,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final FakePhotoRepository photos = FakePhotoRepository();
      addTearDown(photos.dispose);
      final FakeProjectRepository projects = FakeProjectRepository();
      addTearDown(projects.dispose);
      final FakeTemplateRepository templates = FakeTemplateRepository();
      addTearDown(templates.dispose);
      await projects.create(aProject(id: 'p1', name: 'Alpha'));
      await templates.save(
        aTemplate(id: 't1', name: 'Assets', projectId: 'p1'),
      );
      await tester.pumpWidget(
        wrap(
          const CaptureScreen(projectId: 'p1'),
          overrides: <Override>[
            photoRepositoryProvider.overrideWith((Ref _) => photos),
            projectRepositoryProvider.overrideWith((Ref _) => projects),
            templateRepositoryProvider.overrideWith((Ref _) => templates),
            capturePersistenceProvider.overrideWith(
              (Ref ref) => CapturePersistenceImpl(
                photos: photos,
                store: TextStore.memory(),
              ),
            ),
            photoPickerProvider.overrideWith(
              (Ref _) => const PhotoPicker.fake(canTakePhoto: true),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    final Finder projectField = find.byKey(
      const ValueKey<String>('capture-project-field'),
    );
    final Finder templateField = find.byKey(
      const ValueKey<String>('capture-template-field'),
    );
    final Finder saveRaw = find.widgetWithText(AppButton, Copy.captureSaveRaw);
    final Finder saveAndProcess = find.byType(AppPrimaryAction);

    const List<({String name, Size size, bool paired})> layouts =
        <({String name, Size size, bool paired})>[
          (name: 'compact portrait', size: Size(360, 740), paired: false),
          (name: 'compact landscape', size: Size(560, 360), paired: false),
          (name: 'medium portrait', size: Size(800, 1200), paired: true),
          (name: 'medium landscape', size: Size(1000, 700), paired: true),
          (name: 'expanded portrait', size: Size(1024, 1366), paired: true),
          (name: 'expanded landscape', size: Size(1366, 1024), paired: true),
        ];

    for (final ({String name, Size size, bool paired}) layout in layouts) {
      testWidgets('in ${layout.name} the selects and saves '
          '${layout.paired ? 'share a row' : 'stack in order'}', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester, size: layout.size);

        final Rect project = tester.getRect(projectField);
        final Rect template = tester.getRect(templateField);
        final Rect raw = tester.getRect(saveRaw);
        final Rect primary = tester.getRect(saveAndProcess);
        if (layout.paired) {
          expect(project.top, template.top);
          expect(project.right, lessThan(template.left));
          expect(project.height, template.height);
          expect(raw.top, primary.top);
          expect(raw.right, lessThan(primary.left));
          expect(primary.width, greaterThan(raw.width));
        } else {
          expect(project.bottom, lessThan(template.top));
          expect(project.left, template.left);
          expect(raw.bottom, lessThan(primary.top));
          expect(raw.width, primary.width);
        }
        expect(projectField, meetsTapTarget());
        expect(templateField, meetsTapTarget());
        expect(saveRaw, meetsTapTarget());
        expect(saveAndProcess, meetsTapTarget());
        expect(_addPhotoIcon, meetsTapTarget());
        expect(tester.takeException(), isNull);
      });

      testWidgets('in ${layout.name} nothing overflows at 200 percent text', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester, size: layout.size, textScale: 2);

        expect(tester.takeException(), isNull);
        expect(saveRaw, meetsTapTarget());
        expect(saveAndProcess, meetsTapTarget());
        expect(projectField, meetsTapTarget());
      });
    }

    testWidgets('the empty tray has no Add photo button and its icon adds', (
      WidgetTester tester,
    ) async {
      await pumpReady(tester, size: const Size(360, 740));

      expect(find.text(Copy.captureNoPhotosHeadline), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, Copy.captureAddPhoto),
        findsNothing,
      );
      expect(find.byTooltip(Copy.captureAddPhoto), findsOneWidget);
      expect(_addPhotoIcon, hasSemanticLabel(Copy.captureAddPhoto));

      await tester.tap(_addPhotoIcon);
      await tester.pumpAndSettle();
      expect(find.text(Copy.captureAddSheetTitle), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, Copy.captureChoosePhoto),
        findsOneWidget,
      );
    });
  });

  testWidgets('inline_fields empty required more validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        InlineFieldsSection(
          fields: const <FieldDef>[],
          values: const <String, Object?>{},
          onChanged: (_, _) {},
        ),
      ),
    );
    expect(find.byKey(const Key('inline-empty')), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        InlineFieldsSection(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.text,
              requiredness: Requiredness.required,
            ),
            FieldDef(fieldKey: 'note', label: 'Note', type: FieldType.longText),
          ],
          values: const <String, Object?>{},
          validationErrors: const <String, String>{'serial': 'bad'},
          onChanged: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Serial'), findsOneWidget);
    expect(find.text('bad'), findsOneWidget);
    expect(find.text(Copy.captureMoreFields), findsOneWidget);
    await tester.tap(find.text(Copy.captureMoreFields));
    await tester.pumpAndSettle();
    expect(find.text('Note'), findsOneWidget);
  });

  testWidgets('camera_permission_gate states', (WidgetTester tester) async {
    for (final PermissionState state in PermissionState.values) {
      final PermissionsService permissions = PermissionsService.fake(
        states: <AppPermission, PermissionState>{AppPermission.camera: state},
      );
      await tester.pumpWidget(
        wrap(
          CameraPermissionGate(
            key: ValueKey<PermissionState>(state),
            permissions: permissions,
            child: const Text('preview'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      if (state == PermissionState.granted) {
        expect(find.text('preview'), findsOneWidget);
      } else {
        expect(find.textContaining('Tapture needs the camera'), findsOneWidget);
      }
    }
  });

  testWidgets('camera_view states and pause resume', (
    WidgetTester tester,
  ) async {
    final CameraService camera = CameraService.fake();
    await tester.pumpWidget(wrap(CameraView(camera: camera)));
    await tester.pumpAndSettle();
    expect(find.textContaining('running'), findsOneWidget);
    await camera.pause();
    await tester.pump();
    await camera.resume();
    await tester.pump();
    expect(find.textContaining('running'), findsOneWidget);
  });

  testWidgets('camera_controls flash zoom grid', (WidgetTester tester) async {
    final CameraService camera = CameraService.fake();
    CameraFlashMode? flash;
    bool? grid;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          height: 400,
          child: CameraControls(
            camera: camera,
            onFlashChanged: (CameraFlashMode m) => flash = m,
            onGridChanged: (bool g) => grid = g,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.flash_off));
    await tester.pumpAndSettle();
    expect(flash, CameraFlashMode.auto);
    await tester.tap(find.byIcon(Icons.grid_off));
    await tester.pumpAndSettle();
    expect(grid, isTrue);
    await tester.tap(find.byIcon(Icons.zoom_in));
    await tester.pumpAndSettle();
    expect(camera.zoom, greaterThan(1));
  });

  testWidgets('document_mode outcomes', (WidgetTester tester) async {
    for (final DocumentBoundary b in DocumentBoundary.values) {
      await tester.pumpWidget(wrap(DocumentMode(boundary: b)));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentMode), findsOneWidget);
    }
  });

  testWidgets('gallery and document picker validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        GalleryPicker(
          picker: PhotoPicker.fake(
            photos: <Uint8List>[
              Uint8List.fromList(<int>[1, 2, 3]),
            ],
          ),
          onImported: (_) {},
        ),
      ),
    );
    await tester.tap(find.text(Copy.captureImportGallery));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      wrap(
        DocumentPicker(
          pickBytes: () async =>
              (bytes: Uint8List.fromList(<int>[1, 2, 3]), filename: 'x.txt'),
          onImported: (_, _) {},
        ),
      ),
    );
    await tester.tap(find.text(Copy.captureImportDocument));
    await tester.pumpAndSettle();
  });

  testWidgets('photo tray reorder type multi', (WidgetTester tester) async {
    final List<PhotoDraft> photos = <PhotoDraft>[
      draft('a', type: 'front'),
      draft('b', type: 'serial', order: 1),
    ];
    await tester.pumpWidget(wrap(PhotoTray(photos: photos, onAdd: () {})));
    // The tray draws no type badge: the select control has that corner (D6).
    expect(find.text(Copy.photoFront), findsNothing);
    expect(_selectTarget, findsNWidgets(2));
    await tester.pumpWidget(
      wrap(PhotoReorder(photos: photos, onReorder: (_) {})),
    );
    expect(find.text('front'), findsOneWidget);
    await tester.pumpWidget(
      wrap(PhotoTypeSheet(lastUsed: 'serial', onSelected: (_) {})),
    );
    expect(find.text(Copy.photoSerial), findsOneWidget);
    await tester.pumpWidget(
      wrap(
        PhotoMultiSelect(
          selectedIds: const <String>{'a'},
          allIds: const <String>['a', 'b'],
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text(Copy.captureSelectedCount(1)), findsOneWidget);
    await tester.tap(find.text(Copy.captureSelectAll));
    await tester.pump();
  });

  testWidgets(
    'viewer crop captions voice barcode recovery rapid storage template',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          PhotoViewerScreen(
            photos: ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[
              draft('a'),
              draft('b'),
            ]),
            missingIds: const <String>{'b'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewerScreen), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          PhotoCropScreen(
            photo: draft('a'),
            onCropped: (PhotoDraft _, Uint8List? _) {},
            onRevert: (_) {},
          ),
        ),
      );
      await tester.tap(find.widgetWithText(AppButton, Copy.photoCrop));
      await tester.pump();
      await tester.tap(find.text('Revert'));
      await tester.pump();

      await tester.pumpWidget(
        wrap(
          RecordCaptionField(value: '', onChanged: (String _) async => true),
        ),
      );
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.pump();

      await tester.pumpWidget(
        wrap(
          MicPermissionGate(
            permissions: PermissionsService.fake(
              states: <AppPermission, PermissionState>{
                AppPermission.microphone: PermissionState.denied,
              },
            ),
            child: const Text('typing'),
          ),
        ),
      );
      expect(find.text('typing'), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          VoiceInputButton(
            stt: const SttService.unavailable(),
            languageTag: 'en',
            onFinal: (_) {},
          ),
        ),
      );
      expect(find.byType(VoiceInputButton), findsOneWidget);

      final AudioRecorderService recorder = AudioRecorderService.fake(
        tick: const Duration(seconds: 1),
      );
      await tester.pumpWidget(
        wrap(
          AudioRecorder(recorder: recorder, relativePath: 'documents/a.wav'),
        ),
      );
      expect(find.text(Copy.audioRecorderStatus('idle', 0)), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await recorder.start('documents/a.wav');
      await tester.pump();
      expect(
        find.text(Copy.audioRecorderStatus('recording', 0)),
        findsOneWidget,
      );
      expect(find.text(Copy.captureStopAudio), findsOneWidget);
      await recorder.stop();
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.pumpWidget(
        wrap(
          BarcodeScannerScreen(
            scanner: BarcodeScannerService.fake(
              hits: const <BarcodeHit>[
                BarcodeHit(rawValue: '123', format: 'code128'),
              ],
            ),
            onConfirmed: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('123'), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          BarcodeContinuousMode(
            scanner: BarcodeScannerService.fake(
              hits: const <BarcodeHit>[
                BarcodeHit(rawValue: '1', format: 'qr'),
                BarcodeHit(rawValue: '1', format: 'qr'),
                BarcodeHit(rawValue: '2', format: 'qr'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(Copy.barcodeScanCount(2)), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          CaptureRecoveryPrompt(
            photoCount: 3,
            onResume: () {},
            onDiscard: () async {},
          ),
        ),
      );
      expect(find.textContaining('3'), findsWidgets);

      await tester.pumpWidget(
        wrap(
          RapidModeScreen(
            items: const <({String recordId, int photoCount})>[
              (recordId: 'r1', photoCount: 2),
            ],
            onCapture: () {},
            onReopen: (_) {},
            preview: const Text('preview'),
          ),
        ),
      );
      expect(find.text(Copy.captureRapidMode), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          const CaptureStorageGuardBanner(
            level: HeadroomState.low,
            freeBytesLabel: '100 MB',
          ),
        ),
      );
      expect(find.text(Copy.captureStorageDismiss), findsOneWidget);
      await tester.tap(find.text(Copy.captureStorageDismiss));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        wrap(
          const CaptureStorageGuardBanner(
            level: HeadroomState.critical,
            freeBytesLabel: '10 MB',
            allowWrites: false,
          ),
        ),
      );
      expect(find.text(Copy.captureStorageExport), findsOneWidget);
    },
  );

  testWidgets('a thumbnail tap opens the photo and the other controls do not', (
    WidgetTester tester,
  ) async {
    PhotoDraft? tapped;
    PhotoDraft? removed;
    final List<String> toggled = <String>[];
    await tester.pumpWidget(
      wrap(
        PhotoTray(
          photos: <PhotoDraft>[draft('a'), draft('b', order: 1)],
          onAdd: () {},
          onTap: (PhotoDraft photo) => tapped = photo,
          onRemove: (PhotoDraft photo) => removed = photo,
          onLongPress: (PhotoDraft photo) => toggled.add(photo.id),
        ),
      ),
    );
    expect(find.text(Copy.capturePhotosSection), findsNothing);
    expect(find.text('Caption'), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('photo-thumb-a')));
    expect(tapped?.id, 'a');
    await tester.tap(find.byTooltip(Copy.captureRemovePhoto).first);
    expect(removed?.id, 'a');
    await tester.tap(_selectTarget.last);
    await tester.longPress(find.byKey(const ValueKey<String>('photo-thumb-a')));
    expect(toggled, <String>['b', 'a']);
    expect(tapped?.id, 'a');
  });

  for (final int turns in <int>[0, 1]) {
    testWidgets('with $turns quarter turns the select and remove controls '
        'are 48dp, apart and flush in the corners', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PhotoTray(
            photos: <PhotoDraft>[
              draft('a').copyWith(rotationDegrees: turns * 90),
            ],
            onAdd: () {},
            onLongPress: (_) {},
            onRemove: (_) {},
            selectedIds: const <String>{'a'},
          ),
        ),
      );
      final Rect select = tester.getRect(_selectTarget);
      final Rect remove = tester.getRect(_removeTarget);
      final Rect thumb = tester.getRect(
        find.byKey(const ValueKey<String>('photo-thumb-a')),
      );
      expect(select.size, const Size.square(48));
      expect(remove.size, const Size.square(48));
      expect(select.overlaps(remove), isFalse);
      expect(
        tester
            .getRect(find.byKey(const ValueKey<String>('photo-corner-select')))
            .topLeft,
        thumb.topLeft,
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey<String>('photo-corner-remove')))
            .topRight,
        thumb.topRight,
      );
      expect(
        tester.getSemantics(_selectTarget),
        matchesSemantics(
          label: Copy.photoSelect,
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_removeTarget),
        matchesSemantics(
          label: Copy.captureRemovePhoto,
          isButton: true,
          hasTapAction: true,
        ),
      );
    });
  }

  testWidgets('a tray without remove draws no remove control', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PhotoTray(
          photos: <PhotoDraft>[draft('a')],
          onAdd: () {},
          onLongPress: (_) {},
        ),
      ),
    );
    expect(_selectTarget, findsOneWidget);
    expect(_removeTarget, findsNothing);
  });

  testWidgets('the preview shows a caption to edit and delete with undo', (
    WidgetTester tester,
  ) async {
    final Map<String, String> writes = <String, String>{};
    await tester.pumpWidget(
      wrap(
        PhotoViewerScreen(
          photos: ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[draft('a')]),
          captions: const <String, String>{'a': 'Boiler room'},
          onCaptionChanged: (PhotoDraft photo, String text) async {
            writes[photo.id] = text;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Boiler room'), findsOneWidget);
    expect(find.byTooltip(Copy.photoCrop), findsOneWidget);
    expect(find.byTooltip(Copy.photoRotate), findsOneWidget);

    await tester.tap(find.text(Copy.photoCaptionEdit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Pump room');
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();
    expect(writes['a'], 'Pump room');
    expect(find.text('Pump room'), findsOneWidget);

    await tester.tap(find.text(Copy.photoCaptionDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.photoCaptionDelete).last);
    await tester.pumpAndSettle();
    expect(writes['a'], '');
    expect(find.text(Copy.photoNoCaption), findsOneWidget);
    expect(find.text(Copy.photoCaptionDelete), findsNothing);

    await tester.tap(find.text(Copy.undo));
    await tester.pumpAndSettle();
    expect(writes['a'], 'Pump room');
    expect(find.text('Pump room'), findsOneWidget);
  });

  testWidgets('a new version shows in the preview at the same position', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<List<PhotoDraft>> photos =
        ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[draft('a'), draft('b')]);
    addTearDown(photos.dispose);
    final Uint8List bytes = _onePixelPng();
    await tester.pumpWidget(
      wrap(
        PhotoViewerScreen(
          photos: photos,
          initialIndex: 1,
          captions: const <String, String>{'b': 'Pump room'},
          images: <String, Uint8List>{'a': bytes, 'b': bytes, 'b2': bytes},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('photo-viewer-image-b')),
      findsOneWidget,
    );

    photos.value = <PhotoDraft>[
      draft('a'),
      draft('b2').copyWith(derivedFrom: 'b'),
    ];
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('photo-viewer-image-b2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('photo-viewer-image-b')),
      findsNothing,
    );
    expect(find.text('Pump room'), findsOneWidget);
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
      ]) {
    testWidgets('in ${layout.name} the preview caption stays on screen', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = layout.size;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        wrap(
          PhotoViewerScreen(
            photos: ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[draft('a')]),
            captions: const <String, String>{'a': 'Boiler room'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Rect edit = tester.getRect(find.text(Copy.photoCaptionEdit));
      expect(edit.bottom, lessThanOrEqualTo(layout.size.height));
    });
  }
}

/// A valid 1×1 PNG.
Uint8List _onePixelPng() {
  final img.Image image = img.Image(width: 1, height: 1);
  return Uint8List.fromList(img.encodePng(image));
}

final Finder _selectTarget = find.byKey(
  const ValueKey<String>('photo-corner-select-target'),
);

final Finder _removeTarget = find.byKey(
  const ValueKey<String>('photo-corner-remove-target'),
);

/// The empty tray's add-photo icon, which is its add action (FBK0000004).
final Finder _addPhotoIcon = find.byKey(
  const ValueKey<String>('empty-state-icon-action'),
);
