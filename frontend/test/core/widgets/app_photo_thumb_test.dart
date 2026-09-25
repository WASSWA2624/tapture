import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';

import '../../support/a11y_matchers.dart';

void main() {
  final double edge = AppConstants.images.thumbnailEdge.toDouble();

  testWidgets('tap opens and long-press selects', (WidgetTester tester) async {
    bool opened = false;
    bool selected = false;
    await _pump(
      tester,
      AppPhotoThumb(
        photo: const PhotoAsset(sha256: 'abc', photoType: PhotoType.front),
        size: edge,
        onTap: () => opened = true,
        onLongPress: () => selected = true,
      ),
    );

    expect(find.byType(AppPhotoThumb), meetsTapTarget());
    expect(find.byType(AppPhotoThumb), hasSemanticLabel('Front'));

    await tester.tap(find.byType(AppPhotoThumb));
    await tester.pump();
    expect(opened, isTrue);
    expect(selected, isFalse);

    await tester.longPress(find.byType(AppPhotoThumb));
    await tester.pump();
    expect(selected, isTrue);
  });

  testWidgets('badge, caption and selection are named, not colour alone', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppPhotoThumb(
        photo: const PhotoAsset(
          sha256: 'abc',
          photoType: PhotoType.serial,
          hasCaption: true,
        ),
        size: edge,
        selected: true,
      ),
    );

    expect(find.byIcon(PhotoType.serial.icon), findsOneWidget);
    expect(find.text('Serial'), findsOneWidget);
    expect(find.byIcon(AppIcons.caption), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.byType(AppPhotoThumb),
      hasSemanticLabel('Serial, captioned, selected'),
    );
  });

  testWidgets('a missing file shows a placeholder and does not throw', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppPhotoThumb(
        photo: const PhotoAsset(
          sha256: 'dead',
          thumbPath: '/definitely/not/a/cached/thumb.jpg',
          sourcePath: '/definitely/not/the/original.jpg',
          photoType: PhotoType.front,
        ),
        size: edge,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('Missing photo'), findsOneWidget);
    expect(
      find.byType(AppPhotoThumb),
      hasSemanticLabel('Missing photo, Front'),
    );
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the original is never the Image source', (
    WidgetTester tester,
  ) async {
    final Directory dir = Directory.systemTemp.createTempSync(
      'tapture_photo_thumb_',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final File original = File('${dir.path}/original.jpg')
      ..writeAsBytesSync(_kPngBytes);
    final File thumb = File('${dir.path}/abc_96.png')
      ..writeAsBytesSync(_kPngBytes);

    await _pump(
      tester,
      AppPhotoThumb(
        photo: PhotoAsset(
          sha256: 'abc',
          thumbPath: thumb.path,
          sourcePath: original.path,
        ),
        size: edge,
      ),
    );

    expect(tester.takeException(), isNull);
    final List<String> paths = _imageFilePaths(tester);
    expect(paths, isNotEmpty);
    expect(paths, everyElement(thumb.path));
    expect(paths, isNot(contains(original.path)));
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio, 1);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
  });

  testWidgets('a missing thumb does not fall back to the original', (
    WidgetTester tester,
  ) async {
    final Directory dir = Directory.systemTemp.createTempSync(
      'tapture_photo_thumb_orig_',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final File original = File('${dir.path}/original.jpg')
      ..writeAsBytesSync(_kPngBytes);

    await _pump(
      tester,
      AppPhotoThumb(
        photo: PhotoAsset(
          sha256: 'abc',
          thumbPath: '${dir.path}/missing_96.png',
          sourcePath: original.path,
        ),
        size: edge,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Missing photo'), findsOneWidget);
    expect(_imageFilePaths(tester), isEmpty);
  });

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Photos',
          body: Wrap(
            spacing: Space.x4,
            runSpacing: Space.x4,
            children: <Widget>[
              AppPhotoThumb(
                photo: const PhotoAsset(
                  sha256: 'a',
                  photoType: PhotoType.ratingPlate,
                  hasCaption: true,
                ),
                size: edge,
                selected: true,
                onTap: () {},
                onLongPress: () {},
              ),
              AppPhotoThumb(
                photo: const PhotoAsset(
                  sha256: 'b',
                  thumbPath: '/missing/photo.jpg',
                ),
                size: edge,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}

List<String> _imageFilePaths(WidgetTester tester) {
  final List<String> paths = <String>[];
  for (final Image image in tester.widgetList<Image>(find.byType(Image))) {
    final String? path = _filePathOf(image.image);
    if (path != null) {
      paths.add(path);
    }
  }
  return paths;
}

String? _filePathOf(ImageProvider<Object> provider) {
  ImageProvider<Object> current = provider;
  if (current is ResizeImage) {
    current = current.imageProvider;
  }
  if (current is FileImage) {
    return current.file.path;
  }
  return null;
}

/// 1×1 PNG used only as a cached thumb file, never as a full photograph.
const List<int> _kPngBytes = <int>[
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
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xDE,
  0x00,
  0x00,
  0x00,
  0x0C,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xD7,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x00,
  0x03,
  0x00,
  0x01,
  0x18,
  0xDD,
  0x8D,
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
];
