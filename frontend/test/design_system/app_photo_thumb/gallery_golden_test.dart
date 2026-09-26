import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        await _pumpGallery(tester, mode.theme);
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

Future<void> _pumpGallery(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
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
      home: const AppPage(title: 'Photo thumbs', body: _GalleryBody()),
    ),
  );
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

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
        const AppSectionHeader(title: 'Checkbox and a turned photo'),
        Wrap(
          spacing: Space.x4,
          runSpacing: Space.x4,
          children: <Widget>[
            AppPhotoThumb(
              photo: const PhotoAsset(sha256: 'g', hasCaption: true),
              size: edge,
              onTap: _ignore,
              onSelectedChanged: _ignoreBool,
            ),
            AppPhotoThumb(
              photo: const PhotoAsset(sha256: 'h'),
              size: edge,
              selected: true,
              onTap: _ignore,
              onSelectedChanged: _ignoreBool,
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
      ],
    );
  }
}

void _ignore() {}

void _ignoreBool(bool _) {}
