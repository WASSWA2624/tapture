import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';
import 'package:tapture/features/capture/presentation/photo_doodle_screen.dart';
import 'package:tapture/features/capture/presentation/photo_type_screen.dart';
import 'package:tapture/features/capture/presentation/photo_viewer_screen.dart';

import '../../support/screen_fonts.dart';
import '../../support/screen_matrix.dart';
import '../../support/screen_probe.dart';
import 'evidence_layout_harness.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets('photo tools scroll without overflow at ${cell.description}', (
      WidgetTester tester,
    ) async {
      final Uint8List bytes = EvidenceLayoutHarness.photoBytes();
      final PhotoDraft photo = EvidenceLayoutHarness.photo();
      final ValueNotifier<List<PhotoDraft>> photos =
          ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[photo]);
      addTearDown(photos.dispose);
      final List<Widget> tools = <Widget>[
        PhotoViewerScreen(
          photos: photos,
          images: <String, Uint8List>{photo.id: bytes},
        ),
        PhotoCropScreen(
          photo: photo,
          bytes: bytes,
          onCropped: (PhotoDraft _, Uint8List? _) {},
          onRevert: (PhotoDraft _) {},
        ),
        PhotoDoodleScreen(
          photo: photo,
          bytes: bytes,
          onDrawn: (PhotoDraft _, Uint8List _) {},
        ),
        PhotoTypeScreen(
          photo: photo,
          bytes: bytes,
          onTyped: (PhotoDraft _, Uint8List _) {},
        ),
      ];
      for (final Widget tool in tools) {
        await EvidenceLayoutHarness.pump(
          tester,
          tool,
          size: cell.size,
          textScale: cell.textScale,
          brightness: cell.brightness,
          outdoor: cell.outdoor,
        );
        expect(tester.takeException(), isNull);
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
        if (tool is PhotoViewerScreen) {
          final Finder crop = find.widgetWithText(AppButton, 'Crop');
          await tester.ensureVisible(crop);
          expect(tester.getSize(crop).height, greaterThanOrEqualTo(48));
          expect(find.text('Delete caption'), findsNothing);
          expect(find.text('Revert'), findsNothing);
        }
      }
    });
  }

  testWidgets('rotation changes the preview only after its durable write', (
    WidgetTester tester,
  ) async {
    final PhotoDraft photo = EvidenceLayoutHarness.photo();
    final Uint8List bytes = EvidenceLayoutHarness.photoBytes();
    final ValueNotifier<List<PhotoDraft>> photos =
        ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[photo]);
    addTearDown(photos.dispose);
    final Completer<bool> write = Completer<bool>();
    await EvidenceLayoutHarness.pump(
      tester,
      PhotoViewerScreen(
        photos: photos,
        images: <String, Uint8List>{photo.id: bytes},
        onRotate: (PhotoDraft visible, int degrees) {
          expect(visible.id, photo.id);
          expect(degrees, 90);
          return write.future;
        },
      ),
    );
    final Finder preview = find.byKey(
      const ValueKey<String>('photo-viewer-image-photo-1'),
    );
    final Finder rotation = find.ancestor(
      of: preview,
      matching: find.byType(RotatedBox),
    );
    await tester.tap(find.widgetWithText(AppButton, 'Rotate'));
    await tester.pump();
    expect(tester.widget<RotatedBox>(rotation).quarterTurns, 0);
    write.complete(true);
    await tester.pumpAndSettle();
    expect(tester.widget<RotatedBox>(rotation).quarterTurns, 1);
    expect(photos.value.single, same(photo));
    expect((tester.widget<Image>(preview).image as MemoryImage).bytes, bytes);
  });

  testWidgets('labelled photo actions address the visible derived photo', (
    WidgetTester tester,
  ) async {
    final PhotoDraft photo = EvidenceLayoutHarness.photo(parent: 'original');
    final ValueNotifier<List<PhotoDraft>> photos =
        ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[photo]);
    addTearDown(photos.dispose);
    final List<String> selected = <String>[];
    await EvidenceLayoutHarness.pump(
      tester,
      PhotoViewerScreen(
        photos: photos,
        images: <String, Uint8List>{
          photo.id: EvidenceLayoutHarness.photoBytes(),
        },
        captions: <String, String>{photo.id: 'Saved caption'},
        onCrop: (PhotoDraft visible) => selected.add('crop:${visible.id}'),
        onDraw: (PhotoDraft visible) => selected.add('draw:${visible.id}'),
        onType: (PhotoDraft visible) => selected.add('type:${visible.id}'),
        onRedact: (PhotoDraft visible) => selected.add('redact:${visible.id}'),
        onRevert: (PhotoDraft visible) => selected.add('revert:${visible.id}'),
      ),
      textScale: 2,
    );
    for (final String label in <String>[
      'Crop',
      'Draw',
      'Type on this photo',
      'Hide parts before sending',
      'Revert',
    ]) {
      final Finder control = find.widgetWithText(AppButton, label);
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pump();
    }
    expect(selected, <String>[
      'crop:photo-1',
      'draw:photo-1',
      'type:photo-1',
      'redact:photo-1',
      'revert:photo-1',
    ]);
    expect(find.text('Saved caption'), findsOneWidget);
    expect(find.text('Delete caption'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
