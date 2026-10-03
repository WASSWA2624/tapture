import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../support/pump_app.dart';
import '../support/screen_probe.dart';

void main() {
  testWidgets('a labelled shared control passes the rendered guidelines', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      AppPage(
        title: 'Projects',
        body: Center(
          child: AppIconButton(
            icon: AppIcons.add,
            semanticLabel: 'Create a project',
            tooltip: 'Create a project',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(await ScreenProbe.accessibilityIssues(tester), isEmpty);
  });

  testWidgets('an unlabelled icon cannot pass the accessibility sweep', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      AppPage(
        title: 'Projects',
        body: Center(
          child: IconButton(icon: const Icon(AppIcons.add), onPressed: () {}),
        ),
      ),
    );
    final List<String> issues = await ScreenProbe.accessibilityIssues(tester);
    expect(issues, isNotEmpty);
    expect(issues.join('\n'), contains('label'));
  });
}
