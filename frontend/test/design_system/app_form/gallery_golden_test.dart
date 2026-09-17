import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

void main() {
  group('app form', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_form_${mode.name}.png'),
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
  tester.view.physicalSize = const Size(400, 1200);
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
      home: const AppPage(title: 'Forms', body: _GalleryBody()),
    ),
  );
}

class _GalleryBody extends StatefulWidget {
  const _GalleryBody();

  @override
  State<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends State<_GalleryBody> {
  final TextEditingController _name = TextEditingController(text: 'Boiler A');
  final TextEditingController _serial = TextEditingController(text: 'SN-01');
  final TextEditingController _emptyName = TextEditingController();
  final TextEditingController _emptySerial = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _serial.dispose();
    _emptyName.dispose();
    _emptySerial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: 'Idle'),
        AppForm(
          fields: <Widget>[
            AppTextField(label: 'Name', controller: _name),
            AppTextField(label: 'Serial', controller: _serial),
          ],
          submitLabel: 'Save',
          onSubmit: () async {},
        ),
        const SizedBox(height: Space.x8),
        const AppSectionHeader(title: 'Error summary'),
        AppForm(
          fields: <Widget>[
            AppTextField(
              label: 'Name',
              controller: _emptyName,
              errorText: 'Required',
            ),
            AppTextField(
              label: 'Serial',
              controller: _emptySerial,
              errorText: 'Too short',
            ),
          ],
          submitLabel: 'Save',
          onSubmit: () async {},
        ),
      ],
    );
  }
}
