import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/screen_fonts.dart';
import '../support/screen_probe.dart';
import '../support/text_contrast_probe.dart';

void main() {
  Future<List<String>> check(WidgetTester tester, Widget child) async {
    await tester.runAsync(ScreenFonts.load);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: child),
        ),
      ),
    );
    return TextContrastProbe.issues(ScreenProbe.visibleParagraphs(tester));
  }

  const TextStyle caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    color: Colors.black,
  );
  testWidgets('a small proportional-font caption retains its paint contrast', (
    WidgetTester tester,
  ) async {
    expect(
      await check(
        tester,
        const Text('Nothing is sent until you confirm it.', style: caption),
      ),
      isEmpty,
    );
  });

  testWidgets('every low-contrast rich-text run fails without rounding', (
    WidgetTester tester,
  ) async {
    final List<String> issues = await check(
      tester,
      const Text.rich(
        TextSpan(
          style: caption,
          children: <InlineSpan>[
            TextSpan(text: 'Readable. '),
            TextSpan(
              text: 'Faint first. ',
              style: TextStyle(color: Color(0xFF777777)),
            ),
            TextSpan(
              text: 'Faint second.',
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
    expect(issues, hasLength(2));
    expect(issues.first, contains('Faint first'));
    expect(issues.last, contains('Faint second'));
    expect(issues.first, contains('below 4.5:1'));
  });

  testWidgets('ancestor opacity is composited before evaluating contrast', (
    WidgetTester tester,
  ) async {
    expect(
      await check(
        tester,
        const Opacity(
          opacity: 0.5,
          child: ColoredBox(
            color: Colors.white,
            child: Text('Faded caption', style: caption),
          ),
        ),
      ),
      <Matcher>[contains('Faded caption')],
    );
  });

  testWidgets(
    'a translucent inner surface is composed over its actual parent',
    (WidgetTester tester) async {
      expect(
        await check(
          tester,
          const ColoredBox(
            color: Colors.black,
            child: ColoredBox(
              color: Color(0xEEFFFFFF),
              child: Text('On a pale panel', style: caption),
            ),
          ),
        ),
        isEmpty,
      );
    },
  );

  testWidgets('large-text threshold follows the rendered size', (
    WidgetTester tester,
  ) async {
    expect(
      await check(
        tester,
        const Text(
          'Large title',
          style: TextStyle(fontSize: 24, color: Color(0xFF888888)),
        ),
      ),
      isEmpty,
    );
    expect(
      await check(
        tester,
        const Text(
          'Small title',
          style: TextStyle(fontSize: 18, color: Color(0xFF888888)),
        ),
      ),
      <Matcher>[contains('Small title')],
    );
  });

  testWidgets('disabled and invisible controls are excluded by their state', (
    WidgetTester tester,
  ) async {
    expect(
      await check(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              enabled: false,
              child: const Text(
                'Unavailable',
                style: TextStyle(color: Color(0xFFDDDDDD)),
              ),
            ),
            const Offstage(child: Text('Hidden', style: caption)),
          ],
        ),
      ),
      isEmpty,
    );
  });

  testWidgets('an unknown gradient background cannot silently pass', (
    WidgetTester tester,
  ) async {
    expect(
      await check(
        tester,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Colors.white, Colors.black],
            ),
          ),
          child: Text('Gradient label', style: caption),
        ),
      ),
      <Matcher>[contains('cannot resolve the background')],
    );
  });
}
