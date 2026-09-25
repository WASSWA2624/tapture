import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';

void main() {
  group('app button', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, theme: mode.theme, size: _gallerySize);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_button_${mode.name}.png'),
        );
      });

      for (final AppButtonVariant variant in AppButtonVariant.values) {
        for (final _ButtonState state in _ButtonState.values) {
          testWidgets('${variant.name} ${state.name} in ${mode.name}', (
            WidgetTester tester,
          ) async {
            await _pumpState(
              tester,
              theme: mode.theme,
              button: AppButton(
                label: 'Save',
                variant: variant,
                icon: state == _ButtonState.icon ? Icons.check : null,
                busy: state == _ButtonState.busy,
                onPressed: state == _ButtonState.disabled ? null : _ignorePress,
              ),
            );
            await tester.pump();
            await expectLater(
              find.byType(Scaffold),
              matchesGoldenFile(
                'goldens/app_button_${mode.name}_${variant.name}_${state.name}.png',
              ),
            );
          });
        }
      }
    }
  });
}

enum _ButtonState { idle, busy, disabled, icon }

List<({String name, ThemeData theme})> get _modes {
  return <({String name, ThemeData theme})>[
    (name: 'light', theme: buildTheme(brightness: Brightness.light)),
    (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
    (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
  ];
}

const Size _gallerySize = Size(400, 800);

Future<void> _pumpGallery(
  WidgetTester tester, {
  required ThemeData theme,
  required Size size,
  Widget? body,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        );
      },
      home: AppPage(title: 'Buttons', body: body ?? const _GalleryBody()),
    ),
  );
}

Future<void> _pumpState(
  WidgetTester tester, {
  required ThemeData theme,
  required Widget button,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(240, 120);
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
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        );
      },
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final AppButtonVariant variant
            in AppButtonVariant.values) ...<Widget>[
          Text(variant.name, style: AppText.section),
          const SizedBox(height: Space.x2),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              AppButton(
                label: 'Save',
                variant: variant,
                onPressed: _ignorePress,
              ),
              AppButton(
                label: 'Save',
                variant: variant,
                busy: true,
                onPressed: _ignorePress,
              ),
              AppButton(label: 'Save', variant: variant),
              AppButton(
                label: 'Save',
                variant: variant,
                icon: Icons.check,
                onPressed: _ignorePress,
              ),
            ],
          ),
          const SizedBox(height: Space.x4),
        ],
        const Text('expanded', style: AppText.section),
        const SizedBox(height: Space.x2),
        const AppButton(
          label: 'Save raw',
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: _ignorePress,
        ),
        const SizedBox(height: Space.x2),
        const AppPrimaryAction(
          label: 'Save and process',
          onPressed: _ignorePress,
        ),
      ],
    );
  }
}

void _ignorePress() {}
