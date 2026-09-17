import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('pull-to-refresh is absent until onRefresh is given', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, onRefresh: null);
    expect(find.byType(RefreshIndicator), findsNothing);

    await _pumpPage(tester, onRefresh: () async {});
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets(
    'the body scrolls without overflow at 200 percent text scale in both orientations',
    (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final Size size in <Size>[
        const Size(400, 800),
        const Size(800, 400),
      ]) {
        await _pumpPage(
          tester,
          size: size,
          body: Column(
            children: <Widget>[
              for (int index = 0; index < 40; index++) Text('Line $index'),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Scrollable), findsOneWidget);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      await expectNoA11yIssues(tester);
    },
  );

  testWidgets('rotation keeps the body', (WidgetTester tester) async {
    await _pumpPage(
      tester,
      size: const Size(400, 800),
      body: const TextField(decoration: InputDecoration(labelText: 'Name')),
    );
    await tester.enterText(find.byType(TextField), 'kept');

    tester.view.physicalSize = const Size(800, 400);
    await tester.pump();

    expect(find.text('kept'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  Widget? body,
  Future<void> Function()? onRefresh,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: AppPage(
        title: 'Page',
        subtitle: 'Subtitle',
        onRefresh: onRefresh,
        body: body ?? const Text('Body', key: Key('app-page-body')),
        footer: FilledButton(onPressed: () {}, child: const Text('Save')),
      ),
    ),
  );
}
