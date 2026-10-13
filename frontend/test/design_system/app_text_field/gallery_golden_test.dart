import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

void main() {
  group('app text field', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_text_field_${mode.name}.png'),
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
  tester.view.physicalSize = const Size(400, 1100);
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
      home: const AppPage(title: 'Text fields', body: _GalleryBody()),
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
    text: 'Ada Lovelace',
  );
  final TextEditingController _required = TextEditingController();
  final TextEditingController _optional = TextEditingController(text: 'bea@x');
  final TextEditingController _error = TextEditingController();
  final TextEditingController _disabled = TextEditingController(text: 'Locked');
  final TextEditingController _multi = TextEditingController(
    text: 'A caption that wraps onto a second line.',
  );

  @override
  void dispose() {
    _empty.dispose();
    _filled.dispose();
    _required.dispose();
    _optional.dispose();
    _error.dispose();
    _disabled.dispose();
    _multi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppTextField(label: 'Empty', controller: _empty, hint: 'Type a name'),
        const SizedBox(height: Space.x4),
        AppTextField(label: 'Filled', controller: _filled, clearable: true),
        const SizedBox(height: Space.x4),
        AppTextField(
          label: 'Name',
          controller: _required,
          requiredness: FieldRequiredness.required,
        ),
        const SizedBox(height: Space.x4),
        AppTextField(
          label: 'Name',
          controller: _optional,
          requiredness: FieldRequiredness.optional,
        ),
        const SizedBox(height: Space.x4),
        AppTextField(label: 'Error', controller: _error, errorText: 'Required'),
        const SizedBox(height: Space.x4),
        AppTextField(label: 'Disabled', controller: _disabled, enabled: false),
        const SizedBox(height: Space.x4),
        AppTextField(
          label: 'Multi-line',
          controller: _multi,
          maxLines: 3,
          maxLength: 80,
        ),
      ],
    );
  }
}
