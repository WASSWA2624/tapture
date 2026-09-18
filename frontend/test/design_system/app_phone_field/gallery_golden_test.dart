import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_phone_field.dart';

void main() {
  group('app phone field', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_phone_field_${mode.name}.png'),
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
  tester.view.physicalSize = const Size(400, 720);
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
      home: const AppPage(title: 'Phone fields', body: _GalleryBody()),
    ),
  );
}

class _GalleryBody extends StatefulWidget {
  const _GalleryBody();

  @override
  State<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends State<_GalleryBody> {
  final TextEditingController _empty = TextEditingController();
  final TextEditingController _filled = TextEditingController(
    text: '+256 700 000000',
  );
  final TextEditingController _error = TextEditingController();
  final TextEditingController _disabled = TextEditingController(
    text: '+256 700 000000',
  );

  @override
  void dispose() {
    _empty.dispose();
    _filled.dispose();
    _error.dispose();
    _disabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppPhoneField(label: 'Empty', controller: _empty),
        const SizedBox(height: Space.x4),
        AppPhoneField(label: 'Filled', controller: _filled),
        const SizedBox(height: Space.x4),
        AppPhoneField(
          label: 'Error',
          controller: _error,
          errorText: Copy.outOfRange,
        ),
        const SizedBox(height: Space.x4),
        AppPhoneField(label: 'Disabled', controller: _disabled, enabled: false),
      ],
    );
  }
}
