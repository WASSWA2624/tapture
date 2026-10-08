import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../support/pump_app.dart';
import '../support/screen_fonts.dart';
import '../support/screen_matrix.dart';
import '../support/screen_probe.dart';

void main() {
  test(
    'matrix retains every width in both orientations, scales and themes',
    () {
      final List<ScreenMatrix> cells = ScreenMatrix.cells.toList();
      expect(cells, hasLength(36));
      expect(cells.map((cell) => cell.description).toSet(), hasLength(36));
      for (final double width in <double>[393, 800, 1200]) {
        final Iterable<ScreenMatrix> sameWidth = cells.where(
          (cell) => cell.size.width == width,
        );
        expect(
          sameWidth.where((cell) => cell.size.width < cell.size.height),
          hasLength(6),
        );
        expect(
          sameWidth.where((cell) => cell.size.width > cell.size.height),
          hasLength(6),
        );
      }
    },
  );

  testWidgets('a responsive row passes while a fixed-height row overflows', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const AppPage(
        title: 'Projects',
        body: Wrap(
          children: <Widget>[
            Text('Create a project'),
            Text('Import a project'),
          ],
        ),
      ),
    );
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
    await pumpApp(
      tester,
      const AppPage(
        title: 'Projects',
        body: SizedBox(
          height: 20,
          child: Column(
            children: <Widget>[
              Text('Create a project'),
              Text('Import a project'),
              Text('Open a project'),
            ],
          ),
        ),
      ),
    );
    final List<String> issues = ScreenProbe.layoutIssues(tester);
    expect(issues, isNotEmpty);
    expect(issues.join('\n'), contains('overflowed'));
  });

  testWidgets('a clipped visible label cannot pass the layout sweep', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const AppPage(
        title: 'Projects',
        body: Align(
          child: SizedBox(
            width: 30,
            child: Text(
              'Create a project to begin capturing records',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
    expect(
      ScreenProbe.layoutIssues(tester),
      contains(startsWith('Truncated label:')),
    );
    expect(ScreenProbe.layoutIssues(tester), hasLength(1));
  });

  testWidgets('laid-out hidden labels do not describe visible clipping', (
    WidgetTester tester,
  ) async {
    const Widget clipped = SizedBox(
      width: 30,
      child: Text('This hidden label is too wide', maxLines: 1),
    );
    await pumpApp(
      tester,
      const AppPage(
        title: 'Projects',
        body: Column(
          children: <Widget>[
            Opacity(opacity: 0, child: clipped),
            Offstage(child: clipped),
            Text('Visible'),
          ],
        ),
      ),
    );
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
  });

  testWidgets('production font metrics retain the visible clipping guard', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(ScreenFonts.load);
    final TextPainter narrow = TextPainter(
      text: const TextSpan(
        text: 'iiiiii',
        style: TextStyle(fontFamily: 'Roboto', fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final TextPainter wide = TextPainter(
      text: const TextSpan(
        text: 'MMMMMM',
        style: TextStyle(fontFamily: 'Roboto', fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(wide.width, greaterThan(narrow.width * 2));
    narrow.dispose();
    wide.dispose();
    await tester.pumpWidget(
      MaterialApp(
        theme: ScreenFonts.theme(buildTheme(brightness: Brightness.light)),
        home: const AppPage(
          title: 'Projects',
          body: Align(
            child: SizedBox(
              width: 30,
              child: Text(
                'Create a project to begin capturing records',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
    expect(ScreenProbe.layoutIssues(tester), <Matcher>[
      startsWith('Truncated label:'),
    ]);
  });
}
