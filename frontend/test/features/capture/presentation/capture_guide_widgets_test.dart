import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_recording_bar.dart';
import 'package:tapture/core/widgets/app_recording_phase.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_guide_card.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
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
    expect(find.text('Photos should show'), findsOneWidget);
    expect(tester.widget<AppCard>(find.byType(AppCard)).onTap, isNull);
    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
      BorderRadius.circular(Radii.md),
    );
    expect(Radii.md, greaterThan(0));
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
      expect(field.minLines, 1);
      expect(field.maxLines, 6);
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
          await expectNoA11yIssues(tester);
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
  for (final double scale in <double>[1, 2]) {
    testWidgets('composer grows, scrolls and shrinks at text scale $scale', (
      tester,
    ) async {
      await _pumpComposer(
        tester,
        cell: ScreenMatrix(
          const Size(393, 886),
          scale,
          Brightness.light,
          false,
        ),
      );
      final Finder input = find.byType(TextField);
      final List<double> heights = <double>[];
      for (final int lines in <int>[0, 1, 3, 6, 8]) {
        await tester.enterText(
          input,
          List<String>.filled(lines, 'Line').join('\n'),
        );
        await tester.pumpAndSettle();
        heights.add(tester.getSize(input).height);
      }
      expect(heights[0], heights[1]);
      expect(heights[2], greaterThan(heights[1]));
      expect(heights[3], greaterThan(heights[2]));
      expect(heights[4], heights[3]);
      final EditableTextState editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editable.renderEditable.maxScrollExtent, greaterThan(0));
      expect(editable.renderEditable.offset.pixels, greaterThan(0));
      expect(editable.renderEditable.selection!.extentOffset, 39);
      final Rect lastCaret = editable.renderEditable.getLocalRectForCaret(
        const TextPosition(offset: 39),
      );
      expect(lastCaret.top, greaterThanOrEqualTo(0));
      expect(
        lastCaret.bottom,
        lessThanOrEqualTo(editable.renderEditable.size.height),
      );
      await tester.enterText(input, 'Short');
      await tester.pumpAndSettle();
      expect(tester.getSize(input).height, heights[1]);
      expect(tester.takeException(), isNull);
    });
  }
  for (final Locale locale in const <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ]) {
    for (final ScreenMatrix cell in <ScreenMatrix>[
      ...ScreenMatrix.cells,
      _reported,
    ]) {
      testWidgets(
        'composer actions and draft survive ${cell.description} $locale',
        (tester) async {
          await _pumpComposer(tester, cell: cell, locale: locale);
          final Finder input = find.byType(TextField);
          await tester.enterText(
            input,
            'Pasted first line\nSecond line\nThird line',
          );
          await tester.pumpAndSettle();
          final TextEditingController controller = tester
              .widget<TextField>(input)
              .controller!;
          controller.selection = const TextSelection.collapsed(offset: 8);
          final Finder add = find.byKey(
            const ValueKey<String>('composer-photo'),
          );
          final Finder mic = find.byKey(
            const ValueKey<String>('app-text-field-dictate'),
          );
          final Finder audio = find.byKey(
            const ValueKey<String>('composer-audio'),
          );
          for (final Finder action in <Finder>[add, mic, audio]) {
            expect(action, findsOneWidget);
            expect(action, meetsTapTarget());
          }
          final bool rtl = locale.countryCode == 'XA';
          expect(
            rtl
                ? tester.getCenter(add).dx > tester.getCenter(mic).dx
                : tester.getCenter(add).dx < tester.getCenter(mic).dx,
            isTrue,
          );
          await _pumpComposer(
            tester,
            cell: cell,
            locale: locale,
            value: 'Late persisted value',
          );
          expect(tester.widget<TextField>(input).controller, same(controller));
          expect(controller.text, 'Pasted first line\nSecond line\nThird line');
          expect(controller.selection.baseOffset, 8);
          await _pumpComposer(
            tester,
            cell: ScreenMatrix(
              Size(cell.size.height, cell.size.width),
              cell.textScale,
              cell.brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
              cell.brightness == Brightness.dark,
            ),
            locale: locale.countryCode == 'XA'
                ? const Locale('en')
                : const Locale('en', 'XA'),
            value: 'Late persisted value',
          );
          expect(tester.widget<TextField>(input).controller, same(controller));
          expect(controller.text, 'Pasted first line\nSecond line\nThird line');
          expect(controller.selection.baseOffset, 8);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final String state in <String>[
    'empty',
    'multiline',
    'audio',
    'photos',
  ]) {
    for (final ({String name, ScreenMatrix cell}) corner
        in ScreenMatrix.corners) {
      testWidgets('feedback 0457 composer visual $state ${corner.name}', (
        tester,
      ) async {
        await _pumpComposer(tester, cell: corner.cell, state: state);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/feedback_0457_composer_${state}_${corner.name}.png',
          ),
        );
      });
    }
  }
}

Future<void> _pumpComposer(
  WidgetTester tester, {
  ScreenMatrix cell = _reported,
  Locale locale = const Locale('en'),
  String state = 'empty',
  String value = '',
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
            child: Padding(
              padding: const EdgeInsets.all(Space.x4),
              child: Builder(
                builder: (context) {
                  final LocalizedCopy copy = Copy.of(context);
                  return DictationScope(
                    service: FakeSttService(),
                    languageTag: 'en',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (state == 'photos')
                          PhotoTray(
                            photos: const <PhotoDraft>[
                              PhotoDraft(
                                id: 'plate',
                                projectId: 'p',
                                relativePath: 'photos/plate.jpg',
                                sha256: 'plate',
                              ),
                            ],
                            thumbBytes: <String, Uint8List>{
                              'plate': Uint8List.fromList(
                                img.encodePng(
                                  img.Image(width: 64, height: 64)
                                    ..clear(img.ColorRgb8(30, 90, 120)),
                                ),
                              ),
                            },
                            showAddAction: false,
                            onAdd: () {},
                            onLongPress: (_) {},
                            onRemove: (_) {},
                          ),
                        RecordCaptionField(
                          value: state == 'multiline'
                              ? 'Serial number\nAsset tag\nOriginal condition'
                              : value,
                          onChanged: (_) async => true,
                          leading: AppIconButton(
                            key: const ValueKey<String>('composer-photo'),
                            icon: AppIcons.addPhoto,
                            semanticLabel: copy.captureAddPhoto,
                            tooltip: copy.captureAddPhoto,
                            outlined: false,
                            onPressed: () {},
                          ),
                          afterDictation: AppIconButton(
                            key: const ValueKey<String>('composer-audio'),
                            icon: AppIcons.recordAudio,
                            semanticLabel: copy.captureRecordAudio,
                            tooltip: copy.captureRecordAudio,
                            outlined: false,
                            onPressed: () {},
                          ),
                        ),
                        if (state == 'audio')
                          AppRecordingBar(
                            phase: AppRecordingPhase.recording,
                            elapsed: const Duration(seconds: 12),
                            onPause: () {},
                            onStop: () {},
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (state == 'photos') {
    await tester.runAsync(() async {
      for (final Image image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(
          image.image,
          tester.element(find.byType(PhotoTray)),
        );
      }
    });
  }
  await tester.pumpAndSettle();
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
