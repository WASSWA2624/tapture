import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

void main() {
  group('app photo thumb', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        final String darkPhoto = _darkPhoto();
        await _decodeThumb(tester, darkPhoto);
        await _pumpGallery(tester, mode.theme, darkPhoto: darkPhoto);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_photo_thumb_${mode.name}.png'),
        );
      });
    }
  });
}

List<({String name, ThemeData theme})> get _modes {
  return <({String name, ThemeData theme})>[
    (name: 'light', theme: buildTheme(brightness: Brightness.light)),
    (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
    (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
  ];
}

/// A dark photo, so the corner controls are shown where FBK0000153 found
/// them hard to see.
String _darkPhoto() {
  final Directory dir = Directory.systemTemp.createTempSync('tapture_thumbs_');
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows keeps the photo open while the image cache holds it.
    }
  });
  final img.Image pixels = img.Image(width: 96, height: 96);
  for (final img.Pixel pixel in pixels) {
    final int shade = 8 + (pixel.x + pixel.y) ~/ 12;
    pixel.setRgb(shade, shade, shade + 4);
  }
  final File file = File('${dir.path}/dark_96.png')
    ..writeAsBytesSync(img.encodePng(pixels));
  return file.path;
}

Future<void> _pumpGallery(
  WidgetTester tester,
  ThemeData theme, {
  required String darkPhoto,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 1000);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: theme,
      home: AppPage(
        title: 'Photo thumbs',
        body: _GalleryBody(darkPhoto: darkPhoto),
      ),
    ),
  );
}

/// Decodes [path] into the image cache under the key the thumbnail uses, in
/// real time, so the golden shows the photo. Doing this after the pump
/// would wait on a load the fake clock has paused.
Future<void> _decodeThumb(WidgetTester tester, String path) async {
  final int edge = AppConstants.images.thumbnailEdge;
  await tester.runAsync(() async {
    final ImageStream stream = ResizeImage(
      FileImage(File(path)),
      width: edge,
      height: edge,
    ).resolve(ImageConfiguration.empty);
    final Completer<void> done = Completer<void>();
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo _, bool _) => done.complete(),
      onError: (Object error, StackTrace? _) => done.completeError(error),
    );
    stream.addListener(listener);
    try {
      await done.future;
    } finally {
      stream.removeListener(listener);
    }
  });
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody({required this.darkPhoto});

  final String darkPhoto;

  @override
  Widget build(BuildContext context) {
    final double edge = AppConstants.images.thumbnailEdge.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppSectionHeader(title: 'Badge, caption, selection, error'),
        Wrap(
          spacing: Space.x4,
          runSpacing: Space.x4,
          children: <Widget>[
            AppPhotoThumb(
              photo: const PhotoAsset(sha256: 'a', photoType: PhotoType.front),
              size: edge,
              onTap: _ignore,
              onLongPress: _ignore,
            ),
            AppPhotoThumb(
              photo: const PhotoAsset(
                sha256: 'b',
                photoType: PhotoType.serial,
                hasCaption: true,
              ),
              size: edge,
              onTap: _ignore,
            ),
            AppPhotoThumb(
              photo: const PhotoAsset(sha256: 'c', photoType: PhotoType.damage),
              size: edge,
              selected: true,
              onTap: _ignore,
              onLongPress: _ignore,
            ),
            AppPhotoThumb(
              photo: const PhotoAsset(sha256: 'd'),
              size: edge,
            ),
            AppPhotoThumb(
              photo: const PhotoAsset(
                sha256: 'e',
                thumbPath: '/missing/cached_96.jpg',
                photoType: PhotoType.document,
              ),
              size: edge,
            ),
            AppPhotoThumb(
              photo: const PhotoAsset(sha256: 'f', photoType: PhotoType.panel),
              size: edge,
              statusLabel: Copy.capturePhotoProcessing,
              onTap: _ignore,
            ),
          ],
        ),
        const SizedBox(height: Space.x4),
        const AppSectionHeader(title: 'Select, remove and a turned photo'),
        Wrap(
          spacing: Space.x4,
          runSpacing: Space.x4,
          children: <Widget>[
            AppPhotoThumb(
              photo: const PhotoAsset(sha256: 'g', hasCaption: true),
              size: edge,
              onTap: _ignore,
              onSelectedChanged: _ignoreBool,
              onRemove: _ignore,
            ),
            AppPhotoThumb(
              photo: const PhotoAsset(sha256: 'h'),
              size: edge,
              selected: true,
              onTap: _ignore,
              onSelectedChanged: _ignoreBool,
              onRemove: _ignore,
            ),
            AppPhotoThumb(
              photo: const PhotoAsset(
                sha256: 'i',
                thumbPath: '/missing/turned_96.jpg',
              ),
              size: edge,
              quarterTurns: 1,
            ),
          ],
        ),
        const SizedBox(height: Space.x4),
        const AppSectionHeader(title: 'Corner controls on a dark photo'),
        Wrap(
          spacing: Space.x4,
          runSpacing: Space.x4,
          children: <Widget>[
            AppPhotoThumb(
              photo: PhotoAsset(sha256: 'j', thumbPath: darkPhoto),
              size: edge,
              onTap: _ignore,
              onSelectedChanged: _ignoreBool,
              onRemove: _ignore,
            ),
            AppPhotoThumb(
              photo: PhotoAsset(sha256: 'k', thumbPath: darkPhoto),
              size: edge,
              selected: true,
              onTap: _ignore,
              onSelectedChanged: _ignoreBool,
              onRemove: _ignore,
            ),
          ],
        ),
      ],
    );
  }
}

void _ignore() {}

void _ignoreBool(bool _) {}
