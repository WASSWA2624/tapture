import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_email_field.dart';
import 'package:tapture/core/widgets/fields/app_phone_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/forms/focus_actions.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('leaving a dirty form prompts before popping', (
    WidgetTester tester,
  ) async {
    final TextEditingController name = TextEditingController();
    addTearDown(name.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return AppPage(
                            title: 'Edit',
                            body: AppForm(
                              fields: <Widget>[
                                AppTextField(label: 'Name', controller: name),
                              ],
                              submitLabel: 'Save',
                              onSubmit: () async {},
                              guardUnsaved: true,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('You have unsaved changes.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('editing an email or phone field marks the form dirty', (
    WidgetTester tester,
  ) async {
    final TextEditingController email = TextEditingController();
    final TextEditingController phone = TextEditingController();
    addTearDown(email.dispose);
    addTearDown(phone.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return AppPage(
                            title: 'Edit',
                            body: AppForm(
                              fields: <Widget>[
                                AppEmailField(
                                  label: 'Email',
                                  controller: email,
                                ),
                                AppPhoneField(
                                  label: 'Phone',
                                  controller: phone,
                                ),
                              ],
                              submitLabel: 'Save',
                              onSubmit: () async {},
                              guardUnsaved: true,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ada@x');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '0711');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('submitting twice runs onSubmit once', (
    WidgetTester tester,
  ) async {
    final TextEditingController name = TextEditingController();
    addTearDown(name.dispose);
    int calls = 0;
    await _pump(
      tester,
      AppForm(
        fields: <Widget>[AppTextField(label: 'Name', controller: name)],
        submitLabel: 'Save',
        onSubmit: () async {
          calls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        },
      ),
    );

    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump(const Duration(milliseconds: 80));
    expect(calls, 1);
  });

  testWidgets('the error summary lists every invalid field', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppForm(
        fields: <Widget>[
          AppTextField(
            label: 'Name',
            controller: TextEditingController(),
            errorText: 'Required',
          ),
          AppTextField(
            label: 'Serial',
            controller: TextEditingController(),
            errorText: 'Too short',
          ),
        ],
        submitLabel: 'Save',
        onSubmit: () async {},
      ),
    );

    expect(find.text('Fix these fields'), findsOneWidget);
    expect(find.text('Name: Required'), findsOneWidget);
    expect(find.text('Serial: Too short'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets(
    'focus advances in visual order and the focused field stays visible',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      final TextEditingController first = TextEditingController();
      final TextEditingController last = TextEditingController();
      addTearDown(first.dispose);
      addTearDown(last.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Scaffold(
            resizeToAvoidBottomInset: true,
            body: AppForm(
              fields: <Widget>[
                AppTextField(label: 'Name', controller: first),
                const SizedBox(height: 480),
                AppTextField(label: 'Notes', controller: last),
              ],
              submitLabel: 'Save',
              onSubmit: () async {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      expect(_editableFocused(tester, 0), isTrue);

      final BuildContext formContext = tester.element(find.byType(AppForm));
      formContext.focusNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_editableFocused(tester, 1), isTrue);

      final Rect field = tester.getRect(find.byType(TextField).last);
      const double keyboardTop = 640 - 280;
      expect(field.bottom, lessThanOrEqualTo(keyboardTop + 1));
      expect(
        field.intersect(const Rect.fromLTWH(0, 0, 400, keyboardTop)).height,
        greaterThan(0),
      );
    },
  );

  testWidgets('a bounded form insets the submit bar', (
    WidgetTester tester,
  ) async {
    final TextEditingController name = TextEditingController();
    addTearDown(name.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AppForm(
            fields: <Widget>[AppTextField(label: 'Name', controller: name)],
            submitLabel: 'Save',
            onSubmit: () async {},
          ),
        ),
      ),
    );
    final Rect submit = tester.getRect(find.byType(AppPrimaryAction));
    expect(submit.left, Space.x4);
    expect(submit.right, 400 - Space.x4);
  });

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Form',
          body: AppForm(
            fields: <Widget>[
              AppTextField(
                label: 'Name',
                controller: TextEditingController(),
                errorText: 'Required',
              ),
              AppTextField(
                label: 'Serial',
                controller: TextEditingController(),
              ),
            ],
            submitLabel: 'Save',
            onSubmit: () async {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

bool _editableFocused(WidgetTester tester, int index) {
  final EditableTextState state = tester.state<EditableTextState>(
    find.byType(EditableText).at(index),
  );
  return state.widget.focusNode.hasFocus;
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
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}
