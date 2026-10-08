import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../support/a11y_matchers.dart';
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

  group('scoped screen accessibility', () {
    testWidgets('a complete 48dp target passes beside a cropped neighbour', (
      WidgetTester tester,
    ) async {
      final ScrollController scroll = ScrollController(initialScrollOffset: 24);
      addTearDown(scroll.dispose);
      await _pumpTapTargets(tester, _scrollingTargets(scroll));
      await tester.pumpAndSettle();

      final Finder neighbour = find.byKey(const ValueKey<String>('neighbour'));
      final Finder selected = find.byKey(const ValueKey<String>('selected'));
      expect(tester.getSemantics(neighbour).rect.height, lessThan(48));
      expect(neighbour, meetsTapTarget());
      expect(selected.hitTestable(), findsOneWidget);
      expect(
        await ScreenProbe.accessibilityIssues(
          tester,
          targets: <Finder>[selected],
        ),
        isEmpty,
      );
    });

    testWidgets('40dp targets fail scoped and default Android and iOS checks', (
      WidgetTester tester,
    ) async {
      await _pumpTapTargets(
        tester,
        Center(child: _tapTarget('selected', size: 40)),
      );
      final Finder selected = find.byKey(const ValueKey<String>('selected'));
      final List<String> scoped = await ScreenProbe.accessibilityIssues(
        tester,
        targets: <Finder>[selected],
      );
      final List<String> wholeTree = await ScreenProbe.accessibilityIssues(
        tester,
      );

      for (final List<String> issues in <List<String>>[scoped, wholeTree]) {
        expect(issues.join('\n'), contains('Size(48.0, 48.0)'));
        expect(issues.join('\n'), contains('Size(44.0, 44.0)'));
        expect(issues.join('\n'), contains('Size(40.0, 40.0)'));
      }
      expect(scoped.join('\n'), contains('Accessibility target paint'));
      expect(scoped.join('\n'), contains('below Size(48.0, 48.0)'));
    });

    testWidgets(
      'a cropped selected 48dp target fails its full painted bounds',
      (WidgetTester tester) async {
        final ScrollController scroll = ScrollController(
          initialScrollOffset: 24,
        );
        addTearDown(scroll.dispose);
        await _pumpTapTargets(tester, _scrollingTargets(scroll));
        await tester.pumpAndSettle();
        final Finder selected = find.byKey(const ValueKey<String>('neighbour'));

        expect(selected, meetsTapTarget());
        final List<String> issues = await ScreenProbe.accessibilityIssues(
          tester,
          targets: <Finder>[selected],
        );
        expect(issues.join('\n'), contains('Accessibility target paint'));
        expect(issues.join('\n'), contains('is clipped by'));
      },
    );

    testWidgets('a 48dp wrapper cannot hide an undersized semantic child', (
      WidgetTester tester,
    ) async {
      await _pumpTapTargets(
        tester,
        Center(
          child: Semantics(
            key: const ValueKey<String>('wrapper'),
            container: true,
            explicitChildNodes: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: _tapTarget('selected', size: 40)),
            ),
          ),
        ),
      );
      final Finder wrapper = find.byKey(const ValueKey<String>('wrapper'));
      expect(wrapper, meetsTapTarget());
      final List<String> issues = await ScreenProbe.accessibilityIssues(
        tester,
        targets: <Finder>[wrapper],
      );

      expect(issues.join('\n'), contains('but found Size(40.0, 40.0)'));
      expect(issues.join('\n'), isNot(contains('below Size(48.0, 48.0)')));
    });

    testWidgets(
      'an unannotated wrapper scopes its descendants without its sibling',
      (WidgetTester tester) async {
        await _pumpTapTargets(
          tester,
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  key: const ValueKey<String>('wrapper'),
                  width: 48,
                  height: 48,
                  child: _tapTarget('selected'),
                ),
                const SizedBox(width: 24),
                _tapTarget('unselected', size: 40),
              ],
            ),
          ),
        );
        final Finder wrapper = find.byKey(const ValueKey<String>('wrapper'));
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            targets: <Finder>[wrapper],
          ),
          isEmpty,
        );
        expect(
          (await ScreenProbe.accessibilityIssues(tester)).join('\n'),
          contains('but found Size(40.0, 40.0)'),
        );
      },
    );

    testWidgets('scoped tap sizes retain whole-tree semantic label checks', (
      WidgetTester tester,
    ) async {
      await _pumpTapTargets(
        tester,
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _tapTarget('selected'),
              IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
            ],
          ),
        ),
      );
      final List<String> issues = await ScreenProbe.accessibilityIssues(
        tester,
        targets: <Finder>[find.byKey(const ValueKey<String>('selected'))],
      );

      expect(
        issues.join('\n'),
        contains('expected tappable node to have semantic label'),
      );
    });

    testWidgets(
      'scoped tap sizes retain whole-tree painted contrast and clipping checks',
      (WidgetTester tester) async {
        await _pumpTapTargets(
          tester,
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _tapTarget('selected'),
                const ColoredBox(
                  color: Colors.white,
                  child: Text(
                    'Unreadable',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  width: 30,
                  child: Text('Truncated label remains a failure', maxLines: 1),
                ),
              ],
            ),
          ),
        );
        final List<String> issues = await ScreenProbe.accessibilityIssues(
          tester,
          targets: <Finder>[find.byKey(const ValueKey<String>('selected'))],
        );

        expect(issues, contains(startsWith('Text contrast: Unreadable')));
        expect(issues, contains(startsWith('Truncated label:')));
      },
    );
  });
}

Future<void> _pumpTapTargets(WidgetTester tester, Widget child) =>
    pumpApp(tester, Scaffold(body: child));

Widget _tapTarget(String id, {double size = 48}) => Semantics(
  key: ValueKey<String>(id),
  container: true,
  button: true,
  label: id,
  onTap: () {},
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: () {},
    child: SizedBox(width: size, height: size),
  ),
);

Widget _scrollingTargets(ScrollController scroll) => Center(
  child: SizedBox(
    width: 200,
    height: 120,
    child: SingleChildScrollView(
      controller: scroll,
      child: Column(
        children: <Widget>[
          _tapTarget('neighbour'),
          const SizedBox(height: 24),
          _tapTarget('selected'),
          const SizedBox(height: 120),
        ],
      ),
    ),
  ),
);
