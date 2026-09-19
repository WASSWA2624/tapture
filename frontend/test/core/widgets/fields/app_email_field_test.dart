import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/app_email_field.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/fakes/fake_stt_service.dart';

void main() {
  testWidgets('uses an email keyboard and the field label', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = _controller();
    await _pump(tester, AppEmailField(label: 'Email', controller: controller));

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.emailAddress);
    expect(field.autofillHints, <String>[AutofillHints.email]);
    expect(find.byType(AppEmailField), meetsTapTarget());
    expect(
      find.byType(AppEmailField),
      hasSemanticLabel(Copy.fieldLabelOptional('Email')),
    );
    expect(find.text(Copy.fieldLabelOptional('Email')), findsOneWidget);
    await expectNoA11yIssues(tester);
  });

  testWidgets('offers no microphone when a dictation scope is above it', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = _controller();
    await _pump(
      tester,
      AppEmailField(label: 'Email', controller: controller),
      withScope: true,
    );
    expect(
      find.byKey(const ValueKey<String>('app-text-field-dictate')),
      findsNothing,
    );
  });
}

TextEditingController _controller() {
  final TextEditingController controller = TextEditingController();
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool withScope = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final Widget page = MaterialApp(
    theme: buildTheme(brightness: Brightness.light),
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
    ),
  );
  await tester.pumpWidget(
    withScope
        ? DictationScope(
            service: FakeSttService(),
            languageTag: 'sw',
            child: page,
          )
        : page,
  );
}
