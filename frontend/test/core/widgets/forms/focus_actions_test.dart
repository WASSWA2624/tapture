import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/forms/focus_actions.dart';

void main() {
  testWidgets('dismissKeyboard unfocuses the active field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const Scaffold(body: TextField(key: Key('field'))),
      ),
    );

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(
      tester
          .state<EditableTextState>(find.byType(EditableText))
          .widget
          .focusNode
          .hasFocus,
      isTrue,
    );

    tester.element(find.byType(Scaffold)).dismissKeyboard();
    await tester.pump();
    expect(
      tester
          .state<EditableTextState>(find.byType(EditableText))
          .widget
          .focusNode
          .hasFocus,
      isFalse,
    );
  });

  testWidgets('focusNext moves in visual order', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: const Column(
              children: <Widget>[
                FocusTraversalOrder(
                  order: NumericFocusOrder(0),
                  child: TextField(key: Key('first')),
                ),
                FocusTraversalOrder(
                  order: NumericFocusOrder(1),
                  child: TextField(key: Key('second')),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('first')));
    await tester.pump();
    tester.element(find.byKey(const Key('first'))).focusNext();
    await tester.pump();

    expect(_focused(tester, const Key('first')), isFalse);
    expect(_focused(tester, const Key('second')), isTrue);
  });
}

bool _focused(WidgetTester tester, Key key) {
  final EditableTextState state = tester.state<EditableTextState>(
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText)),
  );
  return state.widget.focusNode.hasFocus;
}
