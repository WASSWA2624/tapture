import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_ink_picker.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_doodle_screen.dart';

void main() {
  testWidgets('drawing can be undone and cleared before it is saved', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoDoodleScreen(
          photo: _photo,
          bytes: _png(8, 8),
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

  testWidgets('each stroke is saved in the ink it was drawn with', (
    WidgetTester tester,
  ) async {
    _surface(tester, const Size(393, 886), 1);
    final List<Uint8List> saved = <Uint8List>[];
    final List<(MarkupInk, int)> styles = <(MarkupInk, int)>[];
    await _open(
      tester,
      onDrawn: saved.add,
      onStyle: (MarkupInk ink, int size) => styles.add((ink, size)),
    );
    final Rect photo = tester.getRect(find.byType(Image));

    await _stroke(tester, photo, 0.25);
    await tester.tap(find.byKey(const ValueKey<String>('ink-blue')));
    await tester.pump();
    await tester.tap(find.text(Copy.markupSizeLarge));
    await tester.pump();
    await _stroke(tester, photo, 0.75);

    expect(styles.last, (MarkupInk.blue, 2));
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(AppButton, Copy.save));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();

    expect(saved, hasLength(1));
    final img.Image image = img.decodeImage(saved.single)!;
    expect(_inkNear(image, 60, 25), _inkRgb(MarkupInk.red));
    expect(_inkNear(image, 60, 75), _inkRgb(MarkupInk.blue));
    expect(_rgb(image.getPixel(60, 50)), <num>[255, 255, 255]);
  });

  testWidgets('a touch in the band beside the photo draws nothing', (
    WidgetTester tester,
  ) async {
    _surface(tester, const Size(393, 886), 1);
    await _open(tester);
    final Rect photo = tester.getRect(find.byType(Image));
    // The square photo fills the width, leaving bands above and below it.
    expect(photo.top, greaterThan(40));

    await tester.dragFrom(
      Offset(photo.left + 20, photo.top - 20),
      Offset(photo.width - 40, 0),
    );
    await tester.pump();

    final AppButton save = tester.widget<AppButton>(
      find.widgetWithText(AppButton, Copy.save),
    );
    expect(save.onPressed, isNull);
    expect(find.byTooltip(Copy.photoUndoDraw), findsOneWidget);
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '800 dp', size: const Size(800, 1000), scale: 1),
        (name: '1200 dp', size: const Size(1200, 800), scale: 1),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
      ]) {
    testWidgets('at ${layout.name} the picker and Save stay reachable', (
      WidgetTester tester,
    ) async {
      _surface(tester, layout.size, layout.scale);
      final List<(MarkupInk, int)> styles = <(MarkupInk, int)>[];
      await _open(
        tester,
        onStyle: (MarkupInk ink, int size) => styles.add((ink, size)),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AppInkPicker), findsOneWidget);

      final Finder green = find.byKey(const ValueKey<String>('ink-green'));
      await tester.ensureVisible(green);
      await tester.pump();
      await tester.tap(green);
      await tester.pump();
      expect(styles.last.$1, MarkupInk.green);

      final Finder save = find.widgetWithText(AppButton, Copy.save);
      await tester.ensureVisible(save);
      await tester.pump();
      final Rect button = tester.getRect(save);
      expect(button.bottom, lessThanOrEqualTo(layout.size.height));
      expect(button.top, greaterThanOrEqualTo(0));
      // The photo keeps room to draw on.
      expect(tester.getSize(find.byType(Image)).shortestSide, greaterThan(100));
    });
  }
}

const PhotoDraft _photo = PhotoDraft(
  id: 'a',
  projectId: 'p',
  relativePath: 'photos/a.jpg',
  sha256: 'a',
);

void _surface(WidgetTester tester, Size size, double scale) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _open(
  WidgetTester tester, {
  void Function(Uint8List png)? onDrawn,
  void Function(MarkupInk ink, int size)? onStyle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: PhotoDoodleScreen(
        photo: _photo,
        bytes: _white(),
        onDrawn: (PhotoDraft _, Uint8List png) => onDrawn?.call(png),
        onStyle: onStyle,
      ),
    ),
  );
  // The photo size is read by the engine, outside the fake clock.
  for (int attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (find.byType(Image).evaluate().isNotEmpty) {
      return;
    }
  }
}

/// A horizontal stroke across the middle of [photo] at [fraction] of its
/// height.
Future<void> _stroke(WidgetTester tester, Rect photo, double fraction) async {
  final double y = photo.top + photo.height * fraction;
  await tester.dragFrom(
    Offset(photo.left + photo.width * 0.1, y),
    Offset(photo.width * 0.8, 0),
  );
  await tester.pump();
}

Uint8List _png(int width, int height) {
  final img.Image image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(1, 2, 3));
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _white() {
  final img.Image image = img.Image(width: 100, height: 100)
    ..clear(img.ColorRgb8(255, 255, 255));
  return Uint8List.fromList(img.encodePng(image));
}

List<num> _rgb(img.Pixel pixel) => <num>[pixel.r, pixel.g, pixel.b];

List<num> _inkRgb(MarkupInk ink) {
  return <num>[
    (ink.color.r * 255).round(),
    (ink.color.g * 255).round(),
    (ink.color.b * 255).round(),
  ];
}

/// The first colour that is not white within two pixels above or below
/// ([x], [y]), so a stroke's rounding does not decide the test.
List<num> _inkNear(img.Image image, int x, int y) {
  for (int row = y - 2; row <= y + 2; row++) {
    final List<num> rgb = _rgb(image.getPixel(x, row));
    if (rgb.join(',') != '255,255,255') {
      return rgb;
    }
  }
  return const <num>[255, 255, 255];
}
