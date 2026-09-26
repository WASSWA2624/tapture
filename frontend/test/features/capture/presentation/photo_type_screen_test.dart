import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_type_screen.dart';

void main() {
  testWidgets('typed words show on the photo in the chosen ink and size', (
    WidgetTester tester,
  ) async {
    _surface(tester, const Size(393, 886), 1);
    await _open(tester);
    expect(_overlay, findsNothing);

    await tester.enterText(_field, 'Valve 3\nleaking');
    await tester.pump();
    expect(_overlay, findsOneWidget);
    final Text words = tester.widget<Text>(
      find.descendant(of: _overlay, matching: find.byType(Text)),
    );
    expect(words.data, 'Valve 3\nleaking');
    expect(words.style?.color, MarkupInk.red.color);
    final double medium = tester.getSize(_overlay).height;

    await tester.tap(find.byKey(const ValueKey<String>('ink-white')));
    await tester.pump();
    await tester.ensureVisible(find.text(Copy.markupSizeLarge));
    await tester.tap(find.text(Copy.markupSizeLarge));
    await tester.pump();
    expect(
      tester
          .widget<Text>(
            find.descendant(of: _overlay, matching: find.byType(Text)),
          )
          .style
          ?.color,
      MarkupInk.white.color,
    );
    expect(tester.getSize(_overlay).height, greaterThan(medium));
  });

  testWidgets('the words start low and centred, and move when dragged', (
    WidgetTester tester,
  ) async {
    _surface(tester, const Size(393, 886), 1);
    await _open(tester);
    await tester.enterText(_field, 'Tag');
    await tester.pump();
    final Rect photo = tester.getRect(find.byType(Image));
    final Offset start = tester.getCenter(_overlay);
    expect(start.dx, moreOrLessEquals(photo.center.dx, epsilon: 1));
    expect(
      start.dy,
      moreOrLessEquals(photo.top + photo.height * 0.8, epsilon: 1),
    );

    await tester.dragFrom(
      photo.center,
      Offset(-photo.width * 0.3, -photo.height * 0.5),
    );
    await tester.pump();
    final Offset moved = tester.getCenter(_overlay);
    expect(moved.dx, lessThan(start.dx - 40));
    expect(moved.dy, lessThan(start.dy - 80));
    expect(photo.contains(moved), isTrue);
  });

  testWidgets('the backing can be switched off', (WidgetTester tester) async {
    _surface(tester, const Size(393, 886), 1);
    await _open(tester);
    await tester.enterText(_field, 'Tag');
    await tester.pump();
    expect(_backingColor(tester), isNotNull);

    final Finder backing = find.byType(AppSwitchTile);
    await tester.ensureVisible(backing);
    await tester.tap(backing);
    await tester.pump();
    expect(_backingColor(tester), isNull);
  });

  testWidgets('Save writes a derived photo with the words on it', (
    WidgetTester tester,
  ) async {
    _surface(tester, const Size(393, 886), 1);
    final List<(PhotoDraft, Uint8List)> typed = <(PhotoDraft, Uint8List)>[];
    await _open(
      tester,
      onTyped: (PhotoDraft draft, Uint8List png) => typed.add((draft, png)),
    );
    await tester.enterText(_field, 'OK');
    await tester.pump();
    await tester.ensureVisible(find.byType(AppPrimaryAction));
    await tester.runAsync(() async {
      await tester.tap(find.byType(AppPrimaryAction));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();

    expect(typed, hasLength(1));
    expect(typed.single.$1.derivedFrom, 'a');
    expect(typed.single.$1.id, isNot('a'));
    final img.Image image = img.decodeImage(typed.single.$2)!;
    expect(image.width, 100);
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '800 dp', size: const Size(800, 1000), scale: 1),
        (name: '1200 dp', size: const Size(1200, 800), scale: 1),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
      ]) {
    testWidgets('at ${layout.name} the field, picker and Save are reachable', (
      WidgetTester tester,
    ) async {
      _surface(tester, layout.size, layout.scale);
      final List<(MarkupInk, int)> styles = <(MarkupInk, int)>[];
      await _open(
        tester,
        onStyle: (MarkupInk ink, int size) => styles.add((ink, size)),
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(_field);
      await tester.enterText(_field, 'Tag');
      await tester.pump();
      final Finder green = find.byKey(const ValueKey<String>('ink-green'));
      await tester.ensureVisible(green);
      await tester.pump();
      await tester.tap(green);
      await tester.pump();
      expect(styles.last.$1, MarkupInk.green);

      await tester.ensureVisible(find.byType(AppPrimaryAction));
      await tester.pump();
      final Rect save = tester.getRect(find.byType(AppPrimaryAction));
      expect(save.bottom, lessThanOrEqualTo(layout.size.height));
      expect(save.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });
  }
}

final Finder _overlay = find.byKey(const ValueKey<String>('type-overlay'));

final Finder _field = find.byWidgetPredicate(
  (Widget widget) =>
      widget is TextField && widget.decoration?.labelText == Copy.photoTypeOn,
);

Color? _backingColor(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(_overlay);
  return (box.decoration as BoxDecoration).color;
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
  void Function(PhotoDraft draft, Uint8List png)? onTyped,
  void Function(MarkupInk ink, int size)? onStyle,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: PhotoTypeScreen(
          photo: _photo,
          bytes: _photoBytes(),
          onTyped: onTyped ?? (PhotoDraft _, Uint8List _) {},
          onStyle: onStyle,
        ),
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

Uint8List _photoBytes() {
  final img.Image image = img.Image(width: 100, height: 100)
    ..clear(img.ColorRgb8(40, 60, 80));
  return Uint8List.fromList(img.encodePng(image));
}
