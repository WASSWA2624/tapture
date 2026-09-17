import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('list, card and detail placeholders are labelled, not blank', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const Column(
        children: <Widget>[
          AppSkeleton(shape: SkeletonShape.list, count: 3),
          AppSkeleton(shape: SkeletonShape.card, count: 1),
          AppSkeleton(shape: SkeletonShape.detail, count: 1),
        ],
      ),
    );

    expect(find.byType(AppSkeleton), findsNWidgets(3));
    expect(find.byType(AppSkeleton), hasSemanticLabel('Loading'));
  });

  testWidgets('a list skeleton occupies the same height as the rows', (
    WidgetTester tester,
  ) async {
    const int count = 3;
    await _pump(
      tester,
      const AppSkeleton(shape: SkeletonShape.list, count: count),
    );

    final Size size = tester.getSize(find.byType(AppSkeleton));
    expect(size.height, greaterThanOrEqualTo(Sizes.minTapTarget * count));
  });

  testWidgets('the inline spinner is labelled and not full-screen', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const AppSkeleton.inline());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AppSkeleton), hasSemanticLabel('Loading'));
    final Size size = tester.getSize(find.byType(AppSkeleton));
    expect(size.width, lessThan(Sizes.minTapTarget));
    expect(size.height, lessThan(Sizes.minTapTarget));
  });

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppPage(
          title: 'Loading',
          body: Column(
            children: <Widget>[
              AppSkeleton(shape: SkeletonShape.list, count: 3),
              AppSkeleton.inline(),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 1200);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}
