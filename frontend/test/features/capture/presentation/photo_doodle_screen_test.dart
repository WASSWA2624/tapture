import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_doodle_screen.dart';

void main() {
  testWidgets('drawing can be undone and cleared before it is saved', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoDoodleScreen(
          photo: const PhotoDraft(
            id: 'a',
            projectId: 'p',
            relativePath: 'photos/a.jpg',
            sha256: 'a',
          ),
          bytes: _png(),
          onDrawn: (PhotoDraft _, Uint8List _) {},
        ),
      ),
    );

    expect(find.text(Copy.photoDraw), findsOneWidget);
    expect(find.text(Copy.save), findsOneWidget);
    await tester.tap(find.byTooltip(Copy.photoUndoDraw));
    await tester.pump();
    await tester.tap(find.byTooltip(Copy.photoClearDraw));
    await tester.pump();
  });
}

Uint8List _png() {
  final img.Image image = img.Image(width: 8, height: 8);
  img.fill(image, color: img.ColorRgb8(1, 2, 3));
  return Uint8List.fromList(img.encodePng(image));
}
