import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/fields/choice_layout.dart';

void main() {
  const List<String> labels = <String>[
    'General',
    'Error',
    'Suggestion',
    'Other',
  ];

  testWidgets('options that fit keep their own widths', (
    WidgetTester tester,
  ) async {
    final double? width = await _measure(tester, labels, 2000);
    expect(width, isNull);
  });

  testWidgets('options that do not fit fall into balanced columns', (
    WidgetTester tester,
  ) async {
    // Room for three of the widest: four options become two rows of two.
    final double? width = await _measure(tester, labels, 420);
    expect(width, isNotNull);
    expect(width, lessThanOrEqualTo((420 - choiceGap) / 2));
    expect(width! * 2 + choiceGap, lessThanOrEqualTo(420));
  });

  testWidgets('a column never drops below one per row', (
    WidgetTester tester,
  ) async {
    final double? width = await _measure(tester, labels, 60);
    expect(width, 60);
  });

  testWidgets('an unbounded row has nothing to divide', (
    WidgetTester tester,
  ) async {
    expect(await _measure(tester, labels, double.infinity), isNull);
    expect(await _measure(tester, const <String>[], 400), isNull);
  });
}

Future<double?> _measure(
  WidgetTester tester,
  List<String> labels,
  double maxWidth,
) async {
  double? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Builder(
        builder: (BuildContext context) {
          result = evenChoiceWidth(context, labels, maxWidth);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}
