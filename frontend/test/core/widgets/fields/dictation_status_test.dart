import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/dictation_phase.dart';
import 'package:tapture/core/widgets/fields/dictation_status.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('each phase names what the microphone is doing', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const DictationStatus(phase: DictationPhase.starting));
    expect(find.text(Copy.dictationStarting), findsOneWidget);
    await _pump(tester, const DictationStatus(phase: DictationPhase.listening));
    expect(find.text(Copy.dictationListening), findsOneWidget);
    await _pump(tester, const DictationStatus(phase: DictationPhase.finishing));
    expect(find.text(Copy.dictationFinishing), findsOneWidget);
  });

  testWidgets('the words heard replace the prompt and are announced', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const DictationStatus(
        phase: DictationPhase.listening,
        heard: ' the pump leaks ',
      ),
    );
    expect(find.text('the pump leaks'), findsOneWidget);
    expect(find.text(Copy.dictationListening), findsNothing);
    expect(
      tester.getSemantics(find.byType(DictationStatus)),
      isSemantics(label: 'the pump leaks', isLiveRegion: true),
    );
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    await expectNoA11yIssues(tester);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
