import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';

import '../../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.load);
  for (final ({String name, ThemeData theme}) mode
      in <({String name, ThemeData theme})>[
        (name: 'light', theme: buildTheme(brightness: Brightness.light)),
        (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
        (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
      ]) {
    for (final double scale in <double>[1, 2]) {
      testWidgets('grouped ${mode.name} text$scale', (
        WidgetTester tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scale == 1
            ? const Size(393, 600)
            : const Size(393, 320);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ScreenFonts.theme(mode.theme),
            builder: (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: AppOverflowMenu(
                  items: <AppOverflowAction>[
                    AppOverflowAction(
                      sectionLabel: Copy.projectMenuCaptureReview,
                      label: Copy.transcribeTitle,
                      icon: AppIcons.transcript,
                      onTap: _ignore,
                    ),
                    AppOverflowAction(
                      sectionLabel: Copy.projectMenuCaptureReview,
                      label: Copy.meetingStartEntry,
                      icon: AppIcons.recordAudio,
                      onTap: _ignore,
                    ),
                    AppOverflowAction(
                      sectionLabel: Copy.projectMenuSetup,
                      label: Copy.contextHierarchyTitle,
                      icon: AppIcons.context,
                      onTap: _ignore,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(AppOverflowMenu));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/app_overflow_grouped_text${scale.toInt()}_${mode.name}.png',
          ),
        );
      });
    }
  }
}

void _ignore() {}
