import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('tapping a compact option toggles it in the set', (
    WidgetTester tester,
  ) async {
    Set<String> value = const <String>{'a'};
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AppCheckboxGroup<String>(
                label: 'Tags',
                value: value,
                options: const <Choice<String>>[
                  Choice<String>('a', 'Alpha'),
                  Choice<String>('b', 'Beta'),
                ],
                onChanged: (Set<String> next) => setState(() => value = next),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(AppCheckboxGroup<String>), meetsTapTarget());
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    await tester.tap(find.text('Beta'));
    await tester.pump();
    expect(value, <String>{'a', 'b'});
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    expect(value, <String>{'b'});
    await expectNoA11yIssues(tester);
  });
}
