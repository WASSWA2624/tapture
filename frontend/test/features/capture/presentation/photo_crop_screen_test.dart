import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';

void main() {
  testWidgets('the frame starts on the photo, not the whole page', (
    WidgetTester tester,
  ) async {
    await _open(tester);
    final Rect photo = tester.getRect(find.byType(Image));
    final Rect frame = tester.getRect(_frame);
    expect(photo.width / photo.height, moreOrLessEquals(2, epsilon: 0.01));
    expect(frame.left, moreOrLessEquals(photo.left + photo.width * 0.1));
    expect(frame.top, moreOrLessEquals(photo.top + photo.height * 0.1));
    expect(frame.right, moreOrLessEquals(photo.right - photo.width * 0.1));
    expect(frame.bottom, moreOrLessEquals(photo.bottom - photo.height * 0.1));
  });

  testWidgets('a corner resizes the frame and a drag moves it inside', (
    WidgetTester tester,
  ) async {
    await _open(tester);
    final Rect photo = tester.getRect(find.byType(Image));
    final Rect before = tester.getRect(_frame);

    await tester.drag(_corner(Alignment.bottomRight), const Offset(-80, -40));
    await tester.pump();
    final Rect resized = tester.getRect(_frame);
    expect(resized.topLeft, before.topLeft);
    expect(resized.width, lessThan(before.width));
    expect(resized.height, lessThan(before.height));

    await tester.drag(_frame, const Offset(2000, 2000));
    await tester.pump();
    final Rect moved = tester.getRect(_frame);
    expect(moved.width, moreOrLessEquals(resized.width));
    expect(moved.height, moreOrLessEquals(resized.height));
    expect(moved.right, moreOrLessEquals(photo.right));
    expect(moved.bottom, moreOrLessEquals(photo.bottom));

    await tester.drag(_corner(Alignment.topLeft), const Offset(4000, 4000));
    await tester.pump();
    final Rect smallest = tester.getRect(_frame);
    expect(smallest.width, moreOrLessEquals(photo.width * 0.1));
    expect(smallest.height, moreOrLessEquals(photo.height * 0.1));
  });

  testWidgets('the crop is the region the frame showed', (
    WidgetTester tester,
  ) async {
    final List<Uint8List> crops = <Uint8List>[];
    await _open(tester, onCropped: crops.add);
    // Frame the left tenth of the photo, which is all red.
    await tester.drag(_corner(Alignment.topLeft), const Offset(-2000, -2000));
    await tester.pump();
    await tester.drag(_corner(Alignment.bottomRight), const Offset(-2000, 0));
    await tester.pump();
    await tester.drag(_corner(Alignment.bottomRight), const Offset(0, 2000));
    await tester.pump();
    await _crop(tester);
    // Then move the same frame to the right edge, which is all blue.
    await tester.drag(_frame, const Offset(2000, 0));
    await tester.pump();
    await _crop(tester);

    expect(crops, hasLength(2));
    expect(_colours(crops[0]), <List<num>>[
      <num>[200, 0, 0],
    ]);
    expect(_colours(crops[1]), <List<num>>[
      <num>[0, 0, 200],
    ]);
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '393 dp', size: const Size(393, 886), scale: 1),
        (name: '1200 dp', size: const Size(1200, 800), scale: 1),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
      ]) {
    testWidgets('at ${layout.name} every handle is a 48dp target', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = layout.size;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester);

      expect(tester.takeException(), isNull);
      final Rect page = Offset.zero & layout.size;
      for (final Alignment corner in <Alignment>[
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.bottomLeft,
        Alignment.bottomRight,
      ]) {
        final Rect handle = tester.getRect(_corner(corner));
        expect(handle.size, const Size.square(Sizes.minTapTarget));
        expect(page.contains(handle.topLeft), isTrue);
        expect(page.contains(handle.bottomRight - const Offset(1, 1)), isTrue);
      }
      expect(
        tester.getRect(find.widgetWithText(AppButton, Copy.photoCrop)).bottom,
        lessThanOrEqualTo(layout.size.height),
      );
    });
  }

  testWidgets('bytes that are not a photo say so and cannot be cropped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PhotoCropScreen(
          photo: _draft,
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          onCropped: (PhotoDraft _, Uint8List? _) {},
          onRevert: (_) {},
        ),
      ),
    );
    await _settleSize(tester, until: find.text(Copy.photoUnreadable));
    expect(find.text(Copy.photoUnreadable), findsOneWidget);
    expect(_frame, findsNothing);
    final AppButton crop = tester.widget<AppButton>(
      find.widgetWithText(AppButton, Copy.photoCrop),
    );
    expect(crop.onPressed, isNull);
  });
}

final Finder _frame = find.byKey(const ValueKey<String>('photo-crop-frame'));

Finder _corner(Alignment corner) {
  return find.byKey(ValueKey<String>('photo-crop-corner-$corner'));
}

const PhotoDraft _draft = PhotoDraft(
  id: 'a',
  projectId: 'p',
  relativePath: 'photos/a.png',
  sha256: 'a',
);

Widget _app(Widget home) {
  return MaterialApp(
    theme: buildTheme(brightness: Brightness.light),
    home: home,
  );
}

Future<void> _open(
  WidgetTester tester, {
  void Function(Uint8List png)? onCropped,
}) async {
  await tester.pumpWidget(
    _app(
      PhotoCropScreen(
        photo: _draft,
        bytes: _twoColours(),
        onCropped: (PhotoDraft _, Uint8List? png) {
          if (png != null) {
            onCropped?.call(png);
          }
        },
        onRevert: (_) {},
      ),
    ),
  );
  await _settleSize(tester, until: _frame);
}

/// The photo size is read by the engine, outside the fake clock.
Future<void> _settleSize(WidgetTester tester, {required Finder until}) async {
  for (int attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (until.evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> _crop(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.widgetWithText(AppButton, Copy.photoCrop));
    await Future<void>.delayed(const Duration(seconds: 2));
  });
  await tester.pump();
}

/// A 40 by 20 photo, red on the left half and blue on the right.
Uint8List _twoColours() {
  final img.Image image = img.Image(width: 40, height: 20);
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: 19,
    y2: 19,
    color: img.ColorRgb8(200, 0, 0),
  );
  img.fillRect(
    image,
    x1: 20,
    y1: 0,
    x2: 39,
    y2: 19,
    color: img.ColorRgb8(0, 0, 200),
  );
  return Uint8List.fromList(img.encodePng(image));
}

/// The distinct colours in [png].
List<List<num>> _colours(Uint8List png) {
  final img.Image image = img.decodeImage(png)!;
  final Set<String> seen = <String>{};
  final List<List<num>> colours = <List<num>>[];
  for (final img.Pixel pixel in image) {
    final List<num> rgb = <num>[pixel.r, pixel.g, pixel.b];
    if (seen.add(rgb.join(','))) {
      colours.add(rgb);
    }
  }
  return colours;
}
