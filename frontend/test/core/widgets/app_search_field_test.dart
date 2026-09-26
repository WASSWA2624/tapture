import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
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

  testWidgets('without onFilter there is no filter button', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppSearchField(hint: 'Search records', onChanged: (_) {}),
    );

    expect(find.byKey(const ValueKey<String>('search-filter')), findsNothing);
    expect(find.byIcon(AppIcons.filter), findsNothing);
  });

  testWidgets('onFilter draws the filter button after the microphone', (
    WidgetTester tester,
  ) async {
    var opened = 0;
    await _pump(
      tester,
      AppSearchField(
        hint: 'Search records',
        onChanged: (_) {},
        onFilter: () => opened++,
      ),
    );

    final Finder filter = find.byKey(const ValueKey<String>('search-filter'));
    expect(filter, findsOneWidget);
    expect(find.byTooltip('Filters'), findsOneWidget);
    expect(filter, hasSemanticLabel('Filters'));
    expect(filter, meetsTapTarget());
    expect(tester.widget<AppIconButton>(filter).selected, isNull);
    final Finder mic = find.byKey(
      const ValueKey<String>('app-text-field-dictate'),
    );
    if (mic.evaluate().isNotEmpty) {
      expect(
        tester.getCenter(filter).dx,
        greaterThan(tester.getCenter(mic).dx),
      );
    }

    await tester.tap(filter);
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('active filters are counted and the button reads selected', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppSearchField(
        hint: 'Search records',
        onChanged: (_) {},
        onFilter: () {},
        activeFilterCount: 3,
      ),
    );

    final Finder filter = find.byKey(const ValueKey<String>('search-filter'));
    expect(find.byTooltip('Filters (3)'), findsOneWidget);
    expect(filter, hasSemanticLabel('Filters (3)'));
    expect(tester.widget<AppIconButton>(filter).selected, isTrue);
  });

  testWidgets('afterMic and the filter button both show', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppSearchField(
        hint: 'Search records',
        onChanged: (_) {},
        onFilter: () {},
        afterMic: const Text('extra'),
      ),
    );

    expect(find.text('extra'), findsOneWidget);
    final Finder filter = find.byKey(const ValueKey<String>('search-filter'));
    expect(filter, findsOneWidget);
    expect(
      tester.getCenter(filter).dx,
      greaterThan(tester.getCenter(find.text('extra')).dx),
    );
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
