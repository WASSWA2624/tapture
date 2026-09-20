import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../../support/a11y_matchers.dart';

void main() {
  _nonScrollingCases();

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

  testWidgets('visible actions stay icon-only; overflow rows carry a label', (
    WidgetTester tester,
  ) async {
    bool overflowTapped = false;
    await _pumpPage(
      tester,
      actions: const <Widget>[
        AppIconButton(
          icon: Icons.search,
          semanticLabel: Copy.search,
          tooltip: Copy.search,
          onPressed: _ignorePress,
        ),
      ],
      overflow: <AppOverflowAction>[
        AppOverflowAction(
          key: const ValueKey<String>('page-templates'),
          label: Copy.navTemplates,
          onTap: () => overflowTapped = true,
        ),
      ],
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text(Copy.search), findsNothing);
    expect(find.text(Copy.navTemplates), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('app-page-overflow')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.navTemplates), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('page-templates')));
    await tester.pumpAndSettle();
    expect(overflowTapped, isTrue);
  });

  testWidgets('a pushed page shows a labelled 48dp back control', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) {
                      return const AppPage(
                        title: 'Child',
                        compactBar: true,
                        body: Text('child'),
                      );
                    },
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppIconButton), findsOneWidget);
    expect(find.byType(AppIconButton), meetsTapTarget());
    expect(
      find.byType(AppIconButton),
      hasSemanticLabel(
        MaterialLocalizations.of(
          tester.element(find.byType(AppIconButton)),
        ).backButtonTooltip,
      ),
    );

    await tester.tap(find.byType(AppIconButton));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

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

void _nonScrollingCases() {
  testWidgets('a non-scrolling page gives its body the height to fill', (
    WidgetTester tester,
  ) async {
    BoxConstraints? given;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
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
          scrollable: false,
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              given = constraints;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(given?.hasBoundedHeight, isTrue);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _ignorePress() {}

Future<void> _pumpPage(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  Widget? body,
  Future<void> Function()? onRefresh,
  List<Widget> actions = const <Widget>[],
  List<AppOverflowAction> overflow = const <AppOverflowAction>[],
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
        actions: actions,
        overflow: overflow,
        onRefresh: onRefresh,
        body: body ?? const Text('Body', key: Key('app-page-body')),
        footer: FilledButton(onPressed: () {}, child: const Text('Save')),
      ),
    ),
  );
}
