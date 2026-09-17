import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_page.dart';

void main() {
  group('app chip', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_chip_${mode.name}.png'),
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
      home: const AppPage(title: 'Chips', body: _GalleryBody()),
    ),
  );
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppChip(label: 'Plain'),
        const SizedBox(height: Space.x4),
        const AppChip(label: 'Selected', selected: true),
        const SizedBox(height: Space.x4),
        const AppChip(label: 'Icon', icon: Icons.place),
        const SizedBox(height: Space.x4),
        const AppChip(label: 'Tappable', selected: true, onTap: _ignore),
        const SizedBox(height: Space.x4),
        const AppChip(label: 'Dismissible', onDismiss: _ignore),
        const SizedBox(height: Space.x4),
        const AppChip(
          label: 'A long facility name that must ellipsize rather than clip',
        ),
        const SizedBox(height: Space.x6),
        AppChipRow(chips: _overflow),
        const SizedBox(height: Space.x4),
        AppChipRow(chips: _overflow, scrollable: true),
      ],
    );
  }
}

void _ignore() {}

final List<AppChip> _overflow = <AppChip>[
  const AppChip(label: 'Alpha'),
  const AppChip(label: 'Bravo'),
  const AppChip(label: 'Charlie'),
  const AppChip(label: 'Delta'),
  const AppChip(label: 'Echo'),
  const AppChip(label: 'Foxtrot'),
  const AppChip(label: 'Golf'),
  const AppChip(label: 'Hotel'),
];
