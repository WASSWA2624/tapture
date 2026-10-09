import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/capture/presentation/capture_guide_card.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/fakes/fake_stt_service.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';

const CaptureGuide _guide = CaptureGuide(
  photoFields: <String>['Serial number', 'Asset tag'],
  captionFields: <String>['Condition', 'Accessories'],
);
const ScreenMatrix _reported = ScreenMatrix(
  Size(393, 886),
  1,
  Brightness.light,
  false,
);
final Finder _panel = find.byKey(
  const ValueKey<String>('capture-caption-guide'),
);

void main() {
  setUpAll(ScreenFonts.load);
  testWidgets('photo guidance is immediate, passive and accessible', (
    tester,
  ) async {
    await _pumpGuide(tester);
    final SemanticsHandle semantics = tester.ensureSemantics();
    expect(find.text('Photos to show'), findsOneWidget);
    expect(
      find.text(Copy.captureGuideItems(_guide.photoFields)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Serial number.*Asset tag')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('capture-guide-toggle')),
      findsNothing,
    );
    expect(find.text(Copy.captureGuideTitle), findsNothing);
    expect(find.text(Copy.captureGuideCaption), findsNothing);
    expect(
      find.text(Copy.captureGuideItems(_guide.captionFields)),
      findsNothing,
    );
    semantics.dispose();
  });

  for (final List<String> captions in <List<String>>[
    <String>[],
    <String>['Condition'],
  ]) {
    testWidgets('no photo guidance reserves no space: $captions', (
      tester,
    ) async {
      await _pumpGuide(
        tester,
        guide: CaptureGuide(
          photoFields: const <String>[],
          captionFields: captions,
        ),
      );
      expect(find.byKey(const ValueKey<String>('capture-guide')), findsNothing);
      expect(find.text(Copy.captureGuidePhotos), findsNothing);
      expect(tester.getSize(find.byType(CaptureGuideCard)).height, 0);
      await _pumpGuide(
        tester,
        guide: CaptureGuide(
          photoFields: const <String>[],
          captionFields: captions,
        ),
        targets: const Text('Existing targets'),
      );
      expect(find.text('Existing targets'), findsOneWidget);
      expect(find.text(Copy.captureGuidePhotos), findsNothing);
    });
  }

  testWidgets(
    'template changes replace original photo labels without stale state',
    (tester) async {
      await _pumpGuide(tester);
      await _pumpGuide(
        tester,
        guide: const CaptureGuide(
          photoFields: <String>['Rear rating plate'],
          captionFields: <String>['Condition'],
        ),
      );
      expect(find.text('Rear rating plate'), findsOneWidget);
      expect(
        find.text(Copy.captureGuideItems(_guide.photoFields)),
        findsNothing,
      );
      expect(_panel, findsNothing);
    },
  );

  testWidgets(
    'typing and pause persist without caption help or close controls',
    (tester) async {
      final List<String> writes = <String>[];
      await _pumpField(
        tester,
        onChanged: (text) async {
          writes.add(text);
          return true;
        },
      );
      await tester.enterText(find.byType(TextField), 'Preserved caption');
      await tester.pump();
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 6);
      expect(field.maxLines, isNull);
      expect(writes, <String>['Preserved caption']);
      expect(_panel, findsNothing);
      expect(
        find.byKey(const ValueKey<String>('capture-caption-guide-close')),
        findsNothing,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(writes.last, 'Preserved caption');
      expect(writes.length, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );

  testWidgets(
    'late persisted value preserves focus and reset replaces the text',
    (tester) async {
      await _pumpField(tester, value: 'Initial');
      await tester.enterText(find.byType(TextField), 'Still typing');
      await tester.pump();
      await _pumpField(tester, value: 'Late save');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Still typing',
      );
      await _pumpField(tester, value: '', resetKey: 1);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(_panel, findsNothing);
    },
  );

  testWidgets('dictation persists words without a caption-help panel', (
    tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    final List<String> writes = <String>[];
    await _pumpField(
      tester,
      speech: speech,
      onChanged: (text) async {
        writes.add(text);
        return true;
      },
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('app-text-field-dictate')),
    );
    await tester.pump();
    expect(speech.isListening, isTrue);
    speech.hear('Dictated caption');
    await tester.pump();
    expect(writes.last, 'Dictated caption');
    expect(_panel, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'failed caption persistence retains the editor and reports failure',
    (tester) async {
      final List<String> failures = <String>[];
      await _pumpField(
        tester,
        onChanged: (_) async => false,
        onWriteFailed: failures.add,
      );
      await tester.enterText(find.byType(TextField), 'Retain on failure');
      await tester.pump();
      expect(failures.single, 'Retain on failure');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Retain on failure',
      );
    },
  );

  for (final Locale locale in const <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ]) {
    for (final ScreenMatrix cell in <ScreenMatrix>[
      ...ScreenMatrix.cells,
      _reported,
    ]) {
      testWidgets(
        'passive guidance wraps ${cell.description} ${locale.toLanguageTag()}',
        (tester) async {
          const CaptureGuide longGuide = CaptureGuide(
            photoFields: <String>[
              'Complete original serial number and manufacturer rating plate',
              'All original asset identification labels and surrounding equipment',
            ],
            captionFields: <String>['Condition'],
          );
          await _pumpGuide(
            tester,
            cell: cell,
            locale: locale,
            guide: longGuide,
          );
          expect(
            find.text(
              Copy.of(
                tester.element(find.byType(CaptureGuideCard)),
              ).captureGuideItems(longGuide.photoFields),
            ),
            findsOneWidget,
          );
          for (final RenderParagraph paragraph
              in tester.allRenderObjects.whereType<RenderParagraph>()) {
            expect(paragraph.didExceedMaxLines, isFalse);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final ({String name, ScreenMatrix cell}) corner
      in ScreenMatrix.corners) {
    testWidgets('feedback 2154 guide visual ${corner.name}', (tester) async {
      await _pumpGuide(tester, cell: corner.cell);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/feedback_2154_guide_${corner.name}.png'),
      );
    });
  }
}

Future<void> _pumpGuide(
  WidgetTester tester, {
  CaptureGuide guide = _guide,
  ScreenMatrix cell = _reported,
  Locale locale = const Locale('en'),
  Widget? targets,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell.size;
  tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: ScreenFonts.theme(
        buildTheme(brightness: cell.brightness, outdoor: cell.outdoor),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Directionality(
        textDirection: locale.countryCode == 'XA'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          body: SingleChildScrollView(
            child: CaptureGuideCard(guide: guide, targets: targets),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpField(
  WidgetTester tester, {
  String value = '',
  Object? resetKey,
  FakeSttService? speech,
  Future<bool> Function(String)? onChanged,
  ValueChanged<String>? onWriteFailed,
}) async {
  final Widget field = RecordCaptionField(
    value: value,
    resetKey: resetKey,
    onChanged: onChanged ?? (_) async => true,
    onWriteFailed: onWriteFailed,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: speech == null
              ? field
              : DictationScope(
                  service: speech,
                  languageTag: 'en',
                  child: field,
                ),
        ),
      ),
    ),
  );
  await tester.pump();
}
