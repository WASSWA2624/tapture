import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import 'a11y_matchers.dart';

/// Reveals a deferred body through the viewport's ordinary scroll gestures.
Future<void> revealScrollableBody(WidgetTester tester, Finder body) async {
  final int attempts =
      find.byType(NestedScrollView, skipOffstage: false).evaluate().length + 1;
  for (
    int attempt = 0;
    body.evaluate().isEmpty && attempt < attempts;
    attempt++
  ) {
    final List<NestedScrollView> viewports = tester
        .widgetList<NestedScrollView>(find.byType(NestedScrollView))
        .toList();
    bool moved = false;
    for (final NestedScrollView viewport in viewports) {
      final Finder target = find.byWidget(viewport);
      if (target.evaluate().isEmpty) continue;
      final NestedScrollViewState state = tester.state(target);
      if (!state.outerController.hasClients) continue;
      final double remaining =
          state.outerController.position.maxScrollExtent -
          state.outerController.offset;
      if (remaining <= 0) continue;
      await tester.drag(target, Offset(0, -remaining - Sizes.minTapTarget));
      await tester.pumpAndSettle();
      moved = true;
      if (body.evaluate().isNotEmpty) break;
    }
    if (!moved) break;
  }
  for (final Element scrollable in find.byType(Scrollable).evaluate()) {
    if (body.evaluate().isNotEmpty) break;
    final ScrollableState state =
        (scrollable as StatefulElement).state as ScrollableState;
    if (state.position.axis != Axis.vertical) continue;
    while (body.evaluate().isEmpty &&
        state.position.pixels < state.position.maxScrollExtent) {
      final double before = state.position.pixels;
      await tester.drag(
        find.byElementPredicate((Element e) => identical(e, scrollable)),
        Offset(0, -state.position.viewportDimension / 2),
      );
      await tester.pumpAndSettle();
      if (state.position.pixels == before) break;
    }
  }
}

/// Checks the rendered empty state, including its reachable next action.
/// A message naming an action without an enabled control does not pass.
Future<void> expectEmptyState(
  WidgetTester tester, {
  required String action,
  Finder? within,
}) async {
  final Finder panel = within == null
      ? find.byType(AppEmptyState)
      : find.descendant(of: within, matching: find.byType(AppEmptyState));
  // A coordinated viewport can defer its body until an oversized header has
  // scrolled away. Expose that real route with ordinary gestures; a missing
  // panel or inert action still fails the checks below.
  // A lazily built list leaves a panel below the fold unbuilt at large text.
  // Scroll it the way a person would, one viewport at a time.
  await revealScrollableBody(tester, panel);
  expect(panel, findsOneWidget);
  final AppEmptyState state = tester.widget<AppEmptyState>(panel);
  if (state.actionLabel == action && state.onAction != null) {
    final Finder button = find.descendant(
      of: panel,
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is AppButton &&
            widget.label == action &&
            widget.onPressed != null,
      ),
    );
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.pump();
    expect(button, meetsTapTarget());
    expect(button.hitTestable(), findsOneWidget);
    return;
  }
  if (state.iconLabel != action || state.onIconTap == null) {
    final Finder pages = find.ancestor(
      of: panel,
      matching: find.byType(AppPage),
    );
    for (final AppPage page in tester.widgetList<AppPage>(pages)) {
      final Widget? footer = page.footer;
      if (footer == null) continue;
      final Finder button = find.descendant(
        of: find.byWidget(footer),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is AppPrimaryAction &&
              widget.label == action &&
              widget.onPressed != null,
        ),
        matchRoot: true,
      );
      if (button.evaluate().isEmpty) continue;
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pump();
      expect(button, meetsTapTarget());
      expect(button.hitTestable(), findsOneWidget);
      return;
    }
  }
  expect(state.iconLabel, action);
  expect(
    state.onIconTap,
    isNotNull,
    reason: 'An empty state needs a next action.',
  );
  final Finder icon = find.descendant(
    of: panel,
    matching: find.byTooltip(action),
  );
  expect(icon, findsOneWidget);
  await tester.ensureVisible(icon);
  await tester.pump();
  expect(icon, meetsTapTarget());
  expect(icon.hitTestable(), findsOneWidget);
}
