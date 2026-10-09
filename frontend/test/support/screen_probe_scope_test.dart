import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_probe.dart';

void main() {
  const ValueKey<String> scope = ValueKey<String>('production-composition');

  Future<void> pumpViolations(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ColoredBox(
                key: scope,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      key: const ValueKey<String>('inside-first'),
                      container: true,
                      button: true,
                      onTap: () {},
                      child: const SizedBox(width: 24, height: 24),
                    ),
                    Semantics(
                      key: const ValueKey<String>('inside-second'),
                      container: true,
                      button: true,
                      onTap: () {},
                      child: const SizedBox(width: 32, height: 32),
                    ),
                    const Text(
                      'Inside low contrast',
                      style: TextStyle(color: Color(0xffdddddd)),
                    ),
                  ],
                ),
              ),
              Semantics(
                container: true,
                button: true,
                onTap: () {},
                child: const SizedBox(width: 20, height: 20),
              ),
              const Text(
                'Outside low contrast',
                style: TextStyle(color: Color(0xffdddddd)),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('scope reports every inside label, size and contrast violation', (
    WidgetTester tester,
  ) async {
    await pumpViolations(tester);
    final List<String> issues = await ScreenProbe.accessibilityIssues(
      tester,
      within: find.byKey(scope),
    );
    expect(
      issues.where((String issue) => issue.contains('semantic label')),
      hasLength(2),
    );
    expect(
      issues.where(
        (String issue) => issue.contains('expected tap target size'),
      ),
      hasLength(2),
    );
    expect(issues.join('\n'), contains('Inside low contrast'));
    expect(issues.join('\n'), isNot(contains('Outside low contrast')));
  });

  testWidgets('default scope retains outside label, size and contrast checks', (
    WidgetTester tester,
  ) async {
    await pumpViolations(tester);
    final List<String> issues = await ScreenProbe.accessibilityIssues(tester);
    expect(
      issues.where((String issue) => issue.contains('semantic label')),
      hasLength(1),
    );
    expect(issues.join('\n'), contains('Outside low contrast'));
    expect(issues.join('\n'), contains('Inside low contrast'));
    expect(issues.join('\n'), contains('20.0'));
  });

  testWidgets(
    'reachable scope reports every paint, label and contrast violation',
    (WidgetTester tester) async {
      await pumpViolations(tester);
      final List<String> issues = await ScreenProbe.accessibilityIssues(
        tester,
        reachableTargets: <Finder>[
          find.byKey(const ValueKey<String>('inside-first')),
          find.byKey(const ValueKey<String>('inside-second')),
        ],
        within: find.byKey(scope),
      );
      expect(
        issues.where(
          (String issue) => issue.contains('Interactive painted region'),
        ),
        hasLength(2),
      );
      expect(
        issues.where((String issue) => issue.contains('semantic label')),
        hasLength(2),
      );
      expect(issues.join('\n'), contains('Inside low contrast'));
      expect(issues.join('\n'), isNot(contains('Outside low contrast')));
    },
  );

  testWidgets('strict and reachable targets are mutually exclusive', (
    WidgetTester tester,
  ) async {
    await pumpViolations(tester);
    final Finder target = find.byKey(const ValueKey<String>('inside-first'));
    expect(
      await ScreenProbe.accessibilityIssues(
        tester,
        targets: <Finder>[target],
        reachableTargets: <Finder>[target],
      ),
      contains(contains('never both')),
    );
  });
}
