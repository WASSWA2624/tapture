import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/theme_preview.dart';

void main() {
  testWidgets('outdoor changes contrast only — geometry matches light', (
    WidgetTester tester,
  ) async {
    final Map<String, Rect> light = await _rects(
      tester,
      theme: buildTheme(brightness: Brightness.light),
    );
    final Map<String, Rect> outdoor = await _rects(
      tester,
      theme: buildOutdoorTheme(Brightness.light),
    );

    expect(outdoor.keys, light.keys);
    for (final MapEntry<String, Rect> entry in light.entries) {
      expect(outdoor[entry.key], entry.value, reason: entry.key);
    }
  });
}

Future<Map<String, Rect>> _rects(
  WidgetTester tester, {
  required ThemeData theme,
}) async {
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
      home: const ThemePreview(),
    ),
  );
  return <String, Rect>{
    'appBar': tester.getRect(find.byType(AppBar)),
    'field': tester.getRect(find.byType(TextField)),
    'filled': tester.getRect(find.widgetWithText(FilledButton, 'Save')),
    'outlined': tester.getRect(find.widgetWithText(OutlinedButton, 'Cancel')),
    'text': tester.getRect(find.widgetWithText(TextButton, 'Skip')),
    'chip': tester.getRect(find.widgetWithText(Chip, 'Chip')),
    'card': tester.getRect(find.byType(Card)),
    'icon': tester.getRect(find.byType(IconButton)),
  };
}
