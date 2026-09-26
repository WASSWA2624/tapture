import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
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

  testWidgets('select and remove sit flush in the top corners', (
    WidgetTester tester,
  ) async {
    final List<bool> toggles = <bool>[];
    int removed = 0;
    await _pump(
      tester,
      AppPhotoThumb(
        photo: const PhotoAsset(sha256: 'abc', photoType: PhotoType.front),
        size: edge,
        onTap: () {},
        onSelectedChanged: toggles.add,
        onRemove: () => removed += 1,
      ),
    );

    final Rect thumb = tester.getRect(find.byType(AppPhotoThumb));
    final Rect select = tester.getRect(_select);
    final Rect remove = tester.getRect(_remove);
    expect(select.topLeft, thumb.topLeft);
    expect(remove.topRight, thumb.topRight);
    expect(select.size, const Size.square(Space.x7));
    expect(remove.size, const Size.square(Space.x7));
    expect(tester.getSize(_selectTarget), const Size.square(48));
    expect(tester.getSize(_removeTarget), const Size.square(48));
    expect(
      tester.getRect(_selectTarget).overlaps(tester.getRect(_removeTarget)),
      isFalse,
    );
    // The type badge moves below the select control.
    expect(
      tester.getRect(find.text('Front')).top,
      greaterThanOrEqualTo(select.bottom),
    );

    await tester.tap(_selectTarget);
    await tester.tap(_removeTarget);
    expect(toggles, <bool>[true]);
    expect(removed, 1);
  });

  testWidgets('a thumb without the callbacks draws no corner controls', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppPhotoThumb(
        photo: const PhotoAsset(sha256: 'abc'),
        size: edge,
        onTap: () {},
      ),
    );
    expect(_selectTarget, findsNothing);
    expect(_removeTarget, findsNothing);
  });

  for (final ({String name, ThemeData theme}) mode
      in <({String name, ThemeData theme})>[
        (name: 'light', theme: buildTheme(brightness: Brightness.light)),
        (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
        (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
      ]) {
    for (final ({String name, Color photo}) shot
        in <({String name, Color photo})>[
          (name: 'black', photo: const Color(0xFF000000)),
          (name: 'white', photo: const Color(0xFFFFFFFF)),
        ]) {
      testWidgets('in ${mode.name} the corner controls read on a '
          '${shot.name} photo', (WidgetTester tester) async {
        final Directory dir = Directory.systemTemp.createTempSync(
          'tapture_photo_corners_',
        );
        addTearDown(() {
          try {
            dir.deleteSync(recursive: true);
          } on FileSystemException {
            // Windows keeps the photo open while the image cache holds it;
            // the system clears its temp folder.
          }
        });
        final img.Image pixels = img.Image(width: 8, height: 8)
          ..clear(
            img.ColorRgb8(
              (shot.photo.r * 255).round(),
              (shot.photo.g * 255).round(),
              (shot.photo.b * 255).round(),
            ),
          );
        final File file = File('${dir.path}/${shot.name}_96.png')
          ..writeAsBytesSync(img.encodePng(pixels));

        for (final bool selected in <bool>[false, true]) {
          await _pump(
            tester,
            Wrap(
              spacing: Space.x4,
              children: <Widget>[
                AppPhotoThumb(
                  photo: PhotoAsset(sha256: 'abc', thumbPath: file.path),
                  size: edge,
                  selected: selected,
                  onTap: () {},
                  onSelectedChanged: (bool _) {},
                  onRemove: () {},
                ),
              ],
            ),
            theme: mode.theme,
          );
          expect(tester.takeException(), isNull);
          await expectNoA11yIssues(tester);
          for (final Finder control in <Finder>[_select, _remove]) {
            final BoxDecoration look = _decorationOf(tester, control);
            final double edgeContrast = <double>[
              _contrast(look.color!, shot.photo),
              _contrast((look.border! as Border).top.color, shot.photo),
            ].reduce((double a, double b) => a > b ? a : b);
            expect(
              edgeContrast,
              greaterThanOrEqualTo(3),
              reason: '$control selected: $selected',
            );
          }
          expect(
            tester.getSemantics(_selectTarget),
            matchesSemantics(
              label: Copy.photoSelect,
              isButton: true,
              hasCheckedState: true,
              isChecked: selected,
              hasTapAction: true,
            ),
          );
        }
        // Selection is a tick as well as a fill (FE-A11Y-05).
        expect(
          find.descendant(of: _select, matching: find.byIcon(AppIcons.check)),
          findsOneWidget,
        );
      });
    }
  }

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

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? buildTheme(brightness: Brightness.light),
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

final Finder _select = find.byKey(
  const ValueKey<String>('photo-corner-select'),
);

final Finder _remove = find.byKey(
  const ValueKey<String>('photo-corner-remove'),
);

final Finder _selectTarget = find.byKey(
  const ValueKey<String>('photo-corner-select-target'),
);

final Finder _removeTarget = find.byKey(
  const ValueKey<String>('photo-corner-remove-target'),
);

BoxDecoration _decorationOf(WidgetTester tester, Finder control) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.descendant(of: control, matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

/// WCAG contrast ratio of [a] against [b].
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double light = la > lb ? la : lb;
  final double dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}
