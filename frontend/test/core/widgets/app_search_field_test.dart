import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/widgets/app_search_field.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('onChanged fires once per debounce window, not per keystroke', (
    WidgetTester tester,
  ) async {
    final List<String> changed = <String>[];
    await _pump(
      tester,
      AppSearchField(hint: 'Search records', onChanged: changed.add),
    );

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump(const Duration(milliseconds: 50));
    expect(changed, isEmpty);

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump(AppConstants.interaction.debounce);
    expect(changed, <String>['ab']);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(changed, <String>['ab', 'abc']);
  });

  testWidgets('a result count is formatted and the field meets 48dp', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppSearchField(
        hint: 'Search records',
        resultCount: 1200,
        onChanged: (_) {},
      ),
    );
    expect(find.text('1,200'), findsOneWidget);
    expect(find.byType(AppSearchField), meetsTapTarget());
    expect(find.byType(AppSearchField), hasSemanticLabel('Search records'));
  });

  testWidgets('an empty parent text clears the field after a query', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const _ParentQuery());
    await tester.enterText(find.byType(TextField), 'crash');
    await tester.pump(AppConstants.interaction.debounce);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'crash',
    );

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });
}

class _ParentQuery extends StatefulWidget {
  const _ParentQuery();

  @override
  State<_ParentQuery> createState() => _ParentQueryState();
}

class _ParentQueryState extends State<_ParentQuery> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppSearchField(
          hint: 'Search records',
          text: _query,
          onChanged: (String value) => setState(() => _query = value),
        ),
        TextButton(
          onPressed: () => setState(() => _query = ''),
          child: const Text('Clear'),
        ),
      ],
    );
  }
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
      home: Scaffold(body: child),
    ),
  );
}
