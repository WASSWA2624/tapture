import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';

import '../../support/fakes/fake_stt_service.dart';

void main() {
  group('app text field, dictation', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('ready and listening in ${mode.name}', (
        WidgetTester tester,
      ) async {
        final FakeSttService speech = FakeSttService();
        await _pumpGallery(tester, mode.theme, speech);
        await tester.tap(
          find.byKey(const ValueKey<String>('app-text-field-dictate')).last,
        );
        await tester.pump();
        speech.hear('the pump leaks at night');
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile(
            'goldens/app_text_field_dictation_${mode.name}.png',
          ),
        );
        await speech.cancel();
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

Future<void> _pumpGallery(
  WidgetTester tester,
  ThemeData theme,
  FakeSttService speech,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 420);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    DictationScope(
      service: speech,
      languageTag: 'en',
      child: MaterialApp(
        key: UniqueKey(),
        debugShowCheckedModeBanner: false,
        themeAnimationDuration: Duration.zero,
        theme: theme,
        home: const AppPage(title: 'Dictation', body: _GalleryBody()),
      ),
    ),
  );
}

class _GalleryBody extends StatefulWidget {
  const _GalleryBody();

  @override
  State<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends State<_GalleryBody> {
  final TextEditingController _name = TextEditingController(text: 'Ada');
  final TextEditingController _notes = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppTextField(label: 'Name', controller: _name, clearable: true),
        const SizedBox(height: Space.x4),
        AppTextField(
          label: 'Your feedback',
          controller: _notes,
          minLines: 3,
          maxLines: 5,
          maxLength: 200,
        ),
      ],
    );
  }
}
