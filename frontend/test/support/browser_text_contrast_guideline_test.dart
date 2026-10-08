import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';

import 'browser_text_contrast_guideline.dart';
import 'screen_fonts.dart';

void main() {
  for (final ({
        String name,
        Color color,
        double size,
        FontWeight weight,
        double opacity,
        bool pass,
      })
      sample
      in <
        ({
          String name,
          Color color,
          double size,
          FontWeight weight,
          double opacity,
          bool pass,
        })
      >[
        (
          name: 'high contrast normal text passes',
          color: Colors.black,
          size: 12,
          weight: FontWeight.normal,
          opacity: 1,
          pass: true,
        ),
        (
          name: '3.5 contrast normal text fails the 4.5 threshold',
          color: const Color(0xff888888),
          size: 12,
          weight: FontWeight.normal,
          opacity: 1,
          pass: false,
        ),
        (
          name: '3.5 contrast 18px text passes the 3.0 threshold',
          color: const Color(0xff888888),
          size: 18,
          weight: FontWeight.normal,
          opacity: 1,
          pass: true,
        ),
        (
          name: '3.5 contrast bold 14px text passes the 3.0 threshold',
          color: const Color(0xff888888),
          size: 14,
          weight: FontWeight.bold,
          opacity: 1,
          pass: true,
        ),
        (
          name: 'low contrast large text fails the 3.0 threshold',
          color: const Color(0xffdddddd),
          size: 18,
          weight: FontWeight.normal,
          opacity: 1,
          pass: false,
        ),
        (
          name: 'faded high contrast declared ink still fails',
          color: Colors.black,
          size: 12,
          weight: FontWeight.normal,
          opacity: 0.05,
          pass: false,
        ),
        (
          name: 'transparent contrast ink still fails',
          color: Colors.transparent,
          size: 12,
          weight: FontWeight.normal,
          opacity: 1,
          pass: false,
        ),
      ]) {
    testWidgets(sample.name, (WidgetTester tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ScreenFonts.theme(buildTheme(brightness: Brightness.light)),
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Opacity(
                opacity: sample.opacity,
                child: Text(
                  'Contrast sample',
                  style: TextStyle(
                    color: sample.color,
                    fontSize: sample.size,
                    fontWeight: sample.weight,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CheckedModeBanner), findsNothing);
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        final Evaluation evaluation = await const BrowserTextContrastGuideline()
            .evaluate(tester);
        expect(evaluation.passed, sample.pass, reason: evaluation.reason);
        if (!sample.pass) {
          expect(evaluation.reason, contains('Expected contrast ratio'));
        }
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('production 12px caption retains high contrast when visible', (
    WidgetTester tester,
  ) async {
    await _prepareSurface(tester);
    final ThemeData theme = ScreenFonts.theme(
      buildTheme(brightness: Brightness.light),
    );
    final String caption = Copy.recycleBinKeptFor(30);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Center(
            child: SizedBox(
              width: 240,
              child: Text(
                caption,
                style: AppText.caption.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CheckedModeBanner), findsNothing);
    final Finder text = find.text(caption);
    final Rect bounds = tester.getRect(text);
    expect(bounds, bounds.intersect(const Rect.fromLTWH(0, 0, 800, 600)));
    expect(text.hitTestable(), findsOneWidget);
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final Evaluation evaluation = await const BrowserTextContrastGuideline()
          .evaluate(tester);
      expect(evaluation.passed, isTrue, reason: evaluation.reason);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('partial solid ink cannot rescue a low contrast shader', (
    WidgetTester tester,
  ) async {
    await _prepareSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ScreenFonts.theme(buildTheme(brightness: Brightness.light)),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) => const LinearGradient(
                colors: <Color>[
                  Colors.black,
                  Colors.black,
                  Color(0xffeeeeee),
                  Color(0xffeeeeee),
                ],
                stops: <double>[0, 0.15, 0.16, 1],
              ).createShader(bounds),
              child: Text(
                Copy.recycleBinKeptFor(30),
                style: const TextStyle(color: Colors.black, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CheckedModeBanner), findsNothing);
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final Evaluation evaluation = await const BrowserTextContrastGuideline()
          .evaluate(tester);
      expect(evaluation.passed, isFalse, reason: evaluation.reason);
      expect(evaluation.reason, contains('Expected contrast ratio'));
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _prepareSurface(WidgetTester tester) async {
  await tester.runAsync(ScreenFonts.load);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(tester.view.reset);
}
