import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';

import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';
import 'capture_workflow_fixture.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'selected Capture keeps intake and both saves reachable ${cell.description}',
      (WidgetTester tester) async {
        await CaptureWorkflowFixture.open(tester, cell: cell);
        final Finder add = find.byKey(
          const ValueKey<String>('capture-add-photo'),
        );
        final Finder photos = find.ancestor(
          of: add,
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is AppSection &&
                widget.title == Copy.capturePhotosSection,
          ),
        );
        expect(photos, findsOneWidget);
        expect(
          tester
              .widget<RecordCaptionField>(find.byType(RecordCaptionField))
              .leading,
          isNull,
        );
        for (final Finder control in <Finder>[
          add,
          find.widgetWithText(AppButton, Copy.captureSaveRaw),
          find.byType(AppPrimaryAction),
        ]) {
          await tester.ensureVisible(control);
          await tester.pumpAndSettle();
          expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
          expect(ScreenProbe.reachabilityIssues(tester, control), isEmpty);
        }
        expect(
          tester.getSize(find.byType(AppPrimaryAction)).height,
          greaterThanOrEqualTo(64),
        );
        expect(find.byType(AppPrimaryAction), findsOneWidget);
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
      },
    );
  }

  testWidgets(
    'offline raw save commits the caption and context without processing',
    (WidgetTester tester) async {
      final CaptureWorkflowFixture fixture = await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(393, 852), 2, Brightness.light, false),
        offline: true,
      );
      final Finder caption = find.descendant(
        of: find.byType(RecordCaptionField),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(caption);
      await tester.enterText(caption, 'Durable offline evidence');
      await tester.pumpAndSettle();
      final before = fixture.session(tester);
      final AppPrimaryAction processing = tester.widget<AppPrimaryAction>(
        find.byType(AppPrimaryAction),
      );
      expect(processing.onPressed, isNotNull);
      expect(find.text(Copy.processingManualFallback), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      final Finder raw = find.widgetWithText(AppButton, Copy.captureSaveRaw);
      await tester.ensureVisible(raw);
      await tester.tap(raw);
      await tester.pumpAndSettle();
      expect(fixture.records.persisted, hasLength(1));
      final saved = fixture.records.persisted.single;
      expect(saved.id, before.id);
      expect(saved.recordCaption, 'Durable offline evidence');
      expect(saved.contextSnapshot, before.contextSnapshot);
      expect(fixture.session(tester).id, isNot(before.id));
      expect(tester.takeException(), isNull);
    },
  );
}
