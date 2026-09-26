import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_ink_picker.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

void main() {
  group('app ink picker', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_ink_picker_${mode.name}.png'),
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
  tester.view.physicalSize = const Size(400, 700);
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
      home: const AppPage(title: 'Ink picker', body: _GalleryBody()),
    ),
  );
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: 'Red, medium'),
        AppInkPicker(
          ink: MarkupInk.red,
          size: 1,
          onInk: _ignoreInk,
          onSize: _ignoreSize,
        ),
        SizedBox(height: Space.x4),
        AppSectionHeader(title: 'White, large'),
        AppInkPicker(
          ink: MarkupInk.white,
          size: 2,
          onInk: _ignoreInk,
          onSize: _ignoreSize,
        ),
        SizedBox(height: Space.x4),
        AppSectionHeader(title: 'Yellow, small'),
        AppInkPicker(
          ink: MarkupInk.yellow,
          size: 0,
          onInk: _ignoreInk,
          onSize: _ignoreSize,
        ),
      ],
    );
  }
}

void _ignoreInk(MarkupInk _) {}

void _ignoreSize(int _) {}
