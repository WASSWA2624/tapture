import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('every state shows an icon and text, not colour alone', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppProgressSteps(
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
    );

    expect(find.text('Read text'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    expect(find.text('Extract fields'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    expect(find.text('Match template'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);

    expect(find.text('Write values'), findsOneWidget);
    expect(find.text('The file could not be read.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      find.byKey(const ValueKey<int>(3)),
      hasSemanticLabel('Write values, Failed, The file could not be read.'),
    );
  });

  testWidgets('a state change announces itself and shifts no later step', (
    WidgetTester tester,
  ) async {
    late StateSetter setState;
    var first = StepState.waiting;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter next) {
          setState = next;
          return AppProgressSteps(
            steps: <ProgressStep>[
              ProgressStep(label: 'Read text', state: first),
              const ProgressStep(
                label: 'Extract fields',
                state: StepState.waiting,
              ),
            ],
          );
        },
      ),
    );

    final Offset before = tester.getTopLeft(find.text('Extract fields'));
    expect(
      find.byKey(const ValueKey<int>(0)),
      hasSemanticLabel('Read text, Waiting'),
    );

    setState(() => first = StepState.done);
    await tester.pump();

    expect(tester.getTopLeft(find.text('Extract fields')), before);
    expect(
      find.byKey(const ValueKey<int>(0)),
      hasSemanticLabel('Read text, Done'),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppPage(
          title: 'Progress',
          body: AppProgressSteps(
            steps: <ProgressStep>[
              ProgressStep(label: 'Read text', state: StepState.done),
              ProgressStep(label: 'Extract fields', state: StepState.running),
              ProgressStep(
                label: 'Write values',
                state: StepState.failed,
                detail: 'The file could not be read.',
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}
