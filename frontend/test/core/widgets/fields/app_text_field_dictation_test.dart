import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/fakes/fake_stt_service.dart';

void main() {
  final Finder mic = find.byKey(
    const ValueKey<String>('app-text-field-dictate'),
  );

  testWidgets('with no scope above it a field offers no microphone', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = _controller();
    await _pump(
      tester,
      AppTextField(label: 'Notes', controller: controller),
      withScope: false,
    );
    expect(mic, findsNothing);
  });

  testWidgets('a free-text field ends in a labelled 48dp microphone', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = _controller();
    await _pump(tester, AppTextField(label: 'Notes', controller: controller));
    expect(mic, findsOneWidget);
    expect(find.byTooltip(Copy.dictateInto('Notes')), findsOneWidget);
    expect(mic, meetsTapTarget());
    await expectNoA11yIssues(tester);
  });

  testWidgets('secret, numeric, read-only and opted-out fields do not', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = _controller();
    await _pump(
      tester,
      Column(
        children: <Widget>[
          AppTextField(label: 'PIN', controller: controller, obscureText: true),
          AppTextField(
            label: 'Count',
            controller: controller,
            keyboardType: TextInputType.number,
          ),
          AppTextField(
            label: 'Email',
            controller: controller,
            keyboardType: TextInputType.emailAddress,
          ),
          AppTextField(label: 'Date', controller: controller, readOnly: true),
          AppTextField(
            label: 'Initials',
            controller: controller,
            dictation: false,
          ),
        ],
      ),
    );
    expect(mic, findsNothing);
  });

  testWidgets('a platform with no recogniser shows no microphone', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppTextField(label: 'Notes', controller: _controller()),
      speech: FakeSttService(isSupported: false),
    );
    expect(mic, findsNothing);
  });

  testWidgets('listening is shown, then the words land tidied at the caret', (
    WidgetTester tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    final TextEditingController controller = _controller('It is slow.');
    final List<String> changes = <String>[];
    await _pump(
      tester,
      AppTextField(
        label: 'Notes',
        controller: controller,
        maxLines: 4,
        onChanged: changes.add,
      ),
      speech: speech,
    );
    await tester.tap(mic);
    await tester.pump();
    expect(speech.listens.single.languageTag, 'sw');
    expect(find.byTooltip(Copy.stopDictating('Notes')), findsOneWidget);

    speech.open();
    await tester.pump();
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).isSelected,
      isTrue,
    );

    speech.hear('also it');
    await tester.pump();
    expect(controller.text, contains('also it'));

    await speech.finish('also it crashes');
    await tester.pump();
    expect(controller.text, 'It is slow. Also it crashes.');
    expect(controller.selection.baseOffset, controller.text.length);
    expect(changes.last, 'It is slow. Also it crashes.');
    expect(find.byTooltip(Copy.dictateInto('Notes')), findsOneWidget);
  });

  testWidgets('typing mid-listen keeps both, without repeating words', (
    WidgetTester tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    final TextEditingController controller = _controller();
    await _pump(
      tester,
      AppTextField(label: 'Notes', controller: controller, maxLines: 4),
      speech: speech,
    );
    await tester.tap(mic);
    await tester.pump();
    speech.hear('the pump');
    await tester.pump();
    expect(controller.text, 'the pump');

    // The operator types; the recogniser keeps sending the whole utterance.
    controller.value = const TextEditingValue(
      text: 'the pump (east)',
      selection: TextSelection.collapsed(offset: 15),
    );
    speech.hear('the pump leaks');
    await tester.pump();
    await speech.finish('the pump leaks badly');
    await tester.pump();
    expect(controller.text, 'the pump (east) leaks badly.');
  });

  testWidgets('a single-line field takes the words as a phrase', (
    WidgetTester tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    final TextEditingController controller = _controller();
    await _pump(
      tester,
      AppTextField(label: 'Type', controller: controller),
      speech: speech,
    );
    await tester.tap(mic);
    await tester.pump();
    await speech.finish('performance');
    await tester.pump();
    expect(controller.text, 'performance');
  });

  testWidgets('the words never push past the length limit', (
    WidgetTester tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    final TextEditingController controller = _controller();
    await _pump(
      tester,
      AppTextField(
        label: 'Notes',
        controller: controller,
        maxLines: 3,
        maxLength: 12,
      ),
      speech: speech,
    );
    await tester.tap(mic);
    await tester.pump();
    await speech.finish('this will not all fit');
    await tester.pump();
    expect(controller.text.length, lessThanOrEqualTo(12));
  });

  testWidgets('a failed listen explains itself and leaves the text', (
    WidgetTester tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    final TextEditingController controller = _controller('Keep');
    await _pump(
      tester,
      AppTextField(label: 'Notes', controller: controller),
      speech: speech,
    );
    await tester.tap(mic);
    await tester.pump();
    await speech.fail(
      const PermissionFailure(message: Copy.dictationNoMicrophone),
    );
    await tester.pump();
    expect(find.text(Copy.dictationNoMicrophone), findsOneWidget);
    expect(controller.text, 'Keep');
  });

  testWidgets('a field that leaves mid-listen cancels the recognition', (
    WidgetTester tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    await _pump(
      tester,
      AppTextField(label: 'Notes', controller: _controller()),
      speech: speech,
    );
    await tester.tap(mic);
    await tester.pump();
    speech.open();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(speech.cancels, 1);
    expect(speech.isListening, isFalse);
  });
}

TextEditingController _controller([String text = '']) {
  final TextEditingController controller = TextEditingController(text: text);
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  FakeSttService? speech,
  bool withScope = true,
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
            service: speech ?? FakeSttService(),
            languageTag: 'sw',
            child: page,
          )
        : page,
  );
}
