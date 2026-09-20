import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('the control is a 48dp labelled icon with no visible text', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _outlined());

    expect(find.byType(AppOverflowMenu), meetsTapTarget());
    expect(find.byType(AppOverflowMenu), hasSemanticLabel(Copy.overflowMenu));
    expect(find.byTooltip(Copy.overflowMenu), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.text(Copy.save), findsNothing);
    await expectNoA11yIssues(tester);
  });

  testWidgets('the default control paints a border', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _outlined());

    final IconButton button = tester.widget<IconButton>(
      find.byType(IconButton),
    );
    expect(button.style, isNull);
    final BorderSide? side = IconButtonTheme.of(
      tester.element(find.byType(IconButton)),
    ).style?.side?.resolve(<WidgetState>{});
    expect(side, isNotNull);
    expect(side, isNot(BorderSide.none));
  });

  testWidgets('a borderless control paints no side', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _borderless());

    final IconButton button = tester.widget<IconButton>(
      find.byType(IconButton),
    );
    expect(button.style?.side?.resolve(<WidgetState>{}), BorderSide.none);
    expect(find.byType(AppOverflowMenu), meetsTapTarget());
    expect(find.byType(AppOverflowMenu), hasSemanticLabel(Copy.overflowMenu));
    expect(find.byTooltip(Copy.overflowMenu), findsOneWidget);
    await expectNoA11yIssues(tester);
  });

  testWidgets('opening the menu shows a labelled row and fires onTap', (
    WidgetTester tester,
  ) async {
    await _expectOpensAndSelects(tester, outlined: true);
  });

  testWidgets('a borderless menu opens and selects the same way', (
    WidgetTester tester,
  ) async {
    await _expectOpensAndSelects(tester, outlined: false);
  });

  testWidgets('hover, focus and press use a token surface', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _borderless());
    final IconButton button = tester.widget<IconButton>(
      find.byType(IconButton),
    );
    final Color fill = tester
        .element(find.byType(IconButton))
        .colors
        .surfaceVariant;
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{
        WidgetState.hovered,
      }),
      fill,
    );
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{
        WidgetState.focused,
      }),
      fill,
    );
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{
        WidgetState.pressed,
      }),
      fill,
    );
    expect(button.style?.backgroundColor?.resolve(<WidgetState>{}), isNull);
  });

  testWidgets('borderless focus traversal shows a visible indicator', (
    WidgetTester tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    await _pump(tester, _borderless());
    final Finder button = find.descendant(
      of: find.byType(AppOverflowMenu),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(button).onPressed, isNotNull);

    final FocusScopeNode scope = FocusScope.of(tester.element(button));
    expect(scope.nextFocus(), isTrue);
    await tester.pump();

    expect(scope.focusedChild?.hasFocus, isTrue);
    expect(
      scope.focusedChild?.context
          ?.findAncestorWidgetOfExactType<AppOverflowMenu>(),
      isNotNull,
    );
    final Color? fill = tester
        .widget<IconButton>(button)
        .style
        ?.backgroundColor
        ?.resolve(<WidgetState>{WidgetState.focused});
    expect(fill, tester.element(button).colors.surfaceVariant);
    expect(fill, isNot(Colors.transparent));
  });

  testWidgets('both variants stay labelled in every theme', (
    WidgetTester tester,
  ) async {
    for (final ThemeData theme in _allThemes) {
      for (final bool outlined in <bool>[true, false]) {
        await _pump(
          tester,
          AppOverflowMenu(
            outlined: outlined,
            items: const <AppOverflowAction>[
              AppOverflowAction(label: Copy.save, onTap: _ignore),
            ],
          ),
          theme: theme,
        );
        expect(find.byType(AppOverflowMenu), meetsTapTarget());
        expect(
          find.byType(AppOverflowMenu),
          hasSemanticLabel(Copy.overflowMenu),
        );
        expect(find.byTooltip(Copy.overflowMenu), findsOneWidget);
        await expectNoA11yIssues(tester);
      }
    }
  });

  testWidgets('nothing clips at 200 percent at 400, 800 and 1200', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final double width in <double>[400, 800, 1200]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const Scaffold(
            body: Row(
              children: <Widget>[
                AppOverflowMenu(
                  items: <AppOverflowAction>[
                    AppOverflowAction(label: Copy.save, onTap: _ignore),
                  ],
                ),
                AppOverflowMenu(
                  outlined: false,
                  items: <AppOverflowAction>[
                    AppOverflowAction(label: Copy.save, onTap: _ignore),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AppOverflowMenu), findsNWidgets(2));
      expect(find.byType(AppOverflowMenu).first, meetsTapTarget());
    }
  });

  testWidgets('borderless stays a control in RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: AppOverflowMenu(
                outlined: false,
                items: <AppOverflowAction>[
                  AppOverflowAction(label: Copy.save, onTap: _ignore),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(AppOverflowMenu), meetsTapTarget());
    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    expect(find.text(Copy.save), findsOneWidget);
  });
}

List<ThemeData> get _allThemes {
  return <ThemeData>[
    buildTheme(brightness: Brightness.light),
    buildTheme(brightness: Brightness.dark),
    buildOutdoorTheme(Brightness.light),
  ];
}

Future<void> _expectOpensAndSelects(
  WidgetTester tester, {
  required bool outlined,
}) async {
  bool tapped = false;
  await _pump(
    tester,
    AppOverflowMenu(
      key: const ValueKey<String>('app-overflow'),
      outlined: outlined,
      items: <AppOverflowAction>[
        AppOverflowAction(
          key: const ValueKey<String>('overflow-save'),
          icon: Icons.save_outlined,
          label: Copy.save,
          onTap: () => tapped = true,
        ),
      ],
    ),
  );

  await tester.tap(find.byKey(const ValueKey<String>('app-overflow')));
  await tester.pumpAndSettle();

  expect(find.text(Copy.save), findsOneWidget);
  expect(find.byIcon(Icons.save_outlined), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey<String>('overflow-save')));
  await tester.pumpAndSettle();
  expect(tapped, isTrue);
  expect(find.text(Copy.save), findsNothing);
}

AppOverflowMenu _outlined() {
  return const AppOverflowMenu(
    key: ValueKey<String>('app-overflow'),
    items: <AppOverflowAction>[
      AppOverflowAction(label: Copy.save, onTap: _ignore),
    ],
  );
}

AppOverflowMenu _borderless() {
  return const AppOverflowMenu(
    key: ValueKey<String>('app-overflow-borderless'),
    outlined: false,
    items: <AppOverflowAction>[
      AppOverflowAction(label: Copy.save, onTap: _ignore),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? buildTheme(brightness: Brightness.light),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void _ignore() {}
