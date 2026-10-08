import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/capture/presentation/capture_guide_card.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/fakes/fake_stt_service.dart';

const CaptureGuide _guide = CaptureGuide(
  photoFields: <String>['Serial number', 'Asset tag'],
  captionFields: <String>['Condition', 'Accessories'],
);

void main() {
  testWidgets('the guide row starts collapsed and opens to both lists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const Scaffold(body: CaptureGuideCard(guide: _guide)),
        ),
      ),
    );

    expect(find.text(Copy.captureGuideTitle), findsOneWidget);
    expect(find.text(Copy.captureGuidePhotos), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('capture-guide-toggle')),
      meetsTapTarget(),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('capture-guide-toggle')),
    );
    await tester.pump();

    expect(find.text(Copy.captureGuidePhotos), findsOneWidget);
    expect(
      find.text(Copy.captureGuideItems(_guide.photoFields)),
      findsOneWidget,
    );
    expect(find.text(Copy.captureGuideCaption), findsOneWidget);
    expect(
      find.text(Copy.captureGuideItems(_guide.captionFields)),
      findsOneWidget,
    );
  });

  testWidgets('an empty guide draws nothing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CaptureGuideCard(
              guide: CaptureGuide(
                photoFields: <String>[],
                captionFields: <String>[],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text(Copy.captureGuideTitle), findsNothing);
  });

  testWidgets('typing shows the caption points above the field', (
    WidgetTester tester,
  ) async {
    await _pumpField(tester);
    expect(_panel, findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(_panel, findsOneWidget);
    expect(
      tester.getBottomLeft(_panel).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(TextField)).dy),
    );

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(_panel, findsNothing);
  });

  testWidgets('recording shows the caption points, and stopping hides them', (
    WidgetTester tester,
  ) async {
    final AudioRecorderService recorder = AudioRecorderService.fake();
    await _pumpField(tester, recorder: recorder);

    await tester.runAsync(() => recorder.start('projects/p/audio/a.wav'));
    await tester.pump();
    expect(_panel, findsOneWidget);

    await tester.runAsync(() => recorder.stop());
    await tester.pump();
    expect(_panel, findsNothing);
  });

  testWidgets('dictating shows the caption points', (
    WidgetTester tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    await _pumpField(tester, speech: speech);

    await tester.tap(
      find.byKey(const ValueKey<String>('app-text-field-dictate')),
    );
    await tester.pump();
    expect(_panel, findsOneWidget);
  });

  testWidgets('close hides the panel through its callback', (
    WidgetTester tester,
  ) async {
    var closed = 0;
    await _pumpField(tester, onClose: () => closed++);
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('capture-caption-guide-close')),
    );
    await tester.pump();
    expect(closed, 1);
  });

  testWidgets('at 200 percent text the panel wraps rather than clips', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpField(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(_panel, findsOneWidget);
  });
}

final Finder _panel = find.byKey(
  const ValueKey<String>('capture-caption-guide'),
);

Future<void> _pumpField(
  WidgetTester tester, {
  AudioRecorderService? recorder,
  FakeSttService? speech,
  VoidCallback? onClose,
}) async {
  final Widget field = RecordCaptionField(
    value: '',
    onChanged: (String _) async => true,
    guide: _guide.captionFields,
    onCloseGuide: onClose ?? () {},
    recorder: recorder,
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
}
