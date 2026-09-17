import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

void main() {
  group('app progress steps', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_progress_steps_${mode.name}.png'),
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
      home: const AppPage(title: 'Progress steps', body: _GalleryBody()),
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
        AppSectionHeader(title: 'Every state'),
        AppProgressSteps(
          steps: <ProgressStep>[
            ProgressStep(label: 'Done', state: StepState.done),
            ProgressStep(label: 'Running', state: StepState.running),
            ProgressStep(label: 'Waiting', state: StepState.waiting),
            ProgressStep(label: 'Failed', state: StepState.failed),
          ],
        ),
        SizedBox(height: Space.x6),
        AppSectionHeader(title: 'Mixed job'),
        AppProgressSteps(
          steps: <ProgressStep>[
            ProgressStep(label: 'Read text', state: StepState.done),
            ProgressStep(label: 'Extract fields', state: StepState.running),
            ProgressStep(label: 'Match template', state: StepState.waiting),
            ProgressStep(
              label: 'Write values',
              state: StepState.failed,
              detail: 'The file could not be read.',
            ),
          ],
        ),
      ],
    );
  }
}
