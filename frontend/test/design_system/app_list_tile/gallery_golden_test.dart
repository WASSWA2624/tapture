import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

void main() {
  group('app list tile', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_list_tile_${mode.name}.png'),
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
      home: AppPage(
        title: 'List tiles',
        body: Column(
          children: <Widget>[
            AppListTile(
              title: 'Comfortable',
              subtitle: 'Plant 3',
              onTap: _ignore,
              onLongPress: _ignore,
            ),
            AppListTile(
              dense: true,
              title: 'Dense',
              subtitle: 'Plant 3',
              onTap: _ignore,
              onLongPress: _ignore,
            ),
            AppListTile(
              title: 'Selected',
              subtitle: 'Plant 3',
              selected: true,
              onTap: _ignore,
              onLongPress: _ignore,
            ),
            const AppListTile(
              title: 'With status',
              subtitle: 'Plant 3',
              status: AppStatusPill.badge(status: RecordStatus.draft),
            ),
            AppListTile(
              title: 'With trailing',
              subtitle: 'Plant 3',
              trailing: AppIconButton(
                icon: Icons.chevron_right,
                semanticLabel: 'Open',
                tooltip: 'Open',
                onPressed: _ignore,
              ),
              onTap: _ignore,
            ),
          ],
        ),
      ),
    ),
  );
}

void _ignore() {}
