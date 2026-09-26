import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/features/exports/exports.dart';
import 'package:tapture/features/projects/presentation/export_summary_view.dart';

void main() {
  for (final ({String name, ThemeData theme}) mode
      in <({String name, ThemeData theme})>[
        (name: 'light', theme: buildTheme(brightness: Brightness.light)),
        (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
        (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
      ]) {
    testWidgets('export summary in ${mode.name}', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: Duration.zero,
          theme: mode.theme,
          home: AppPage(
            title: 'Export project',
            body: ExportSummaryView(
              summary: (
                projectName: 'Testing',
                records: 3,
                photos: 5,
                audioClips: 1,
                unprocessed: 1,
                needsReview: 1,
                approved: 1,
                templates: const <ExportTemplateCount>[
                  (name: 'Assets', records: 2),
                  (name: 'Rooms', records: 1),
                ],
                firstCapturedAt: DateTime.utc(2026, 9, 24, 9),
                lastCapturedAt: DateTime.utc(2026, 9, 25, 16),
              ),
              destination: 'Downloads › Tapture',
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(AppPage),
        matchesGoldenFile('goldens/export_summary_${mode.name}.png'),
      );
    });
  }
}
