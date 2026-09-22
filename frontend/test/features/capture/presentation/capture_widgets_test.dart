import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/features/capture/data/photo_repository_impl.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/audio_recorder.dart';
import 'package:tapture/features/capture/presentation/barcode_continuous_mode.dart';
import 'package:tapture/features/capture/presentation/barcode_scanner_screen.dart';
import 'package:tapture/features/capture/presentation/camera_controls.dart';
import 'package:tapture/features/capture/presentation/camera_permission_gate.dart';
import 'package:tapture/features/capture/presentation/camera_view.dart';
import 'package:tapture/features/capture/presentation/caption_scope_selector.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_recovery_prompt.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/capture/presentation/capture_storage_guard.dart';
import 'package:tapture/features/capture/presentation/document_mode.dart';
import 'package:tapture/features/capture/presentation/document_picker.dart';
import 'package:tapture/features/capture/presentation/gallery_picker.dart';
import 'package:tapture/features/capture/presentation/inline_fields_section.dart';
import 'package:tapture/features/capture/presentation/mic_permission_gate.dart';
import 'package:tapture/features/capture/presentation/photo_caption_sheet.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';
import 'package:tapture/features/capture/presentation/photo_multi_select.dart';
import 'package:tapture/features/capture/presentation/photo_reorder.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/photo_type_sheet.dart';
import 'package:tapture/features/capture/presentation/photo_viewer_screen.dart';
import 'package:tapture/features/capture/presentation/rapid_mode_screen.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/capture/presentation/template_picker_sheet.dart';
import 'package:tapture/features/capture/presentation/voice_input_button.dart';
import 'package:tapture/features/templates/domain/field_def.dart';

import '../../../support/fakes/fake_photo_repository.dart';

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
    expect(find.text(Copy.captureTitle), findsOneWidget);
    expect(find.text(Copy.captureSaveRaw), findsOneWidget);
    expect(find.text(Copy.captureSaveAndAnalyse), findsOneWidget);
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
    expect(find.text('front'), findsWidgets);
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
            photos: <PhotoDraft>[draft('a'), draft('b')],
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
            onCropped: (_) {},
            onRevert: (_) {},
          ),
        ),
      );
      await tester.tap(find.text('Crop'));
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
          PhotoCaptionSheet(
            initial: 'existing',
            onSave: (String _) async => true,
          ),
        ),
      );
      expect(find.text(Copy.capturePhotoCaption), findsWidgets);

      await tester.pumpWidget(
        wrap(
          CaptionScopeSelector(
            scope: CaptionScope.thisPhoto,
            thisCount: 1,
            selectedCount: 3,
            allCount: 7,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text(Copy.captionScopeSelected(3)), findsOneWidget);
      expect(find.text(Copy.captionScopeAll(7)), findsOneWidget);

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

      await tester.pumpWidget(
        wrap(
          AudioRecorder(
            recorder: AudioRecorderService.fake(),
            relativePath: 'documents/a.wav',
          ),
        ),
      );
      expect(find.text(Copy.captureRecordAudio), findsOneWidget);

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

      await tester.pumpWidget(
        wrap(
          TemplatePickerSheet(
            templates: const <({String id, String name, int lastUsedMs})>[
              (id: 't1', name: 'One', lastUsedMs: 2),
              (id: 't2', name: 'Two', lastUsedMs: 1),
            ],
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('One'), findsOneWidget);
      await tester.pumpWidget(
        wrap(
          TemplatePickerSheet(
            templates: const <({String id, String name, int lastUsedMs})>[
              (id: 't1', name: 'Only', lastUsedMs: 1),
            ],
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.byType(SizedBox), findsWidgets);
    },
  );
}
