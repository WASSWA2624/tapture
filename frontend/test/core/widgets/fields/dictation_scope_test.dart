import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';

import '../../../support/fakes/fake_stt_service.dart';

void main() {
  testWidgets('a field with no scope above it finds none', (
    WidgetTester tester,
  ) async {
    DictationScope? found = DictationScope(
      service: FakeSttService(),
      languageTag: 'en',
      child: const SizedBox.shrink(),
    );
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          found = DictationScope.maybeOf(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(found, isNull);
  });

  testWidgets('a new voice language or offline choice reaches the fields', (
    WidgetTester tester,
  ) async {
    final FakeSttService speech = FakeSttService();
    final List<String> seen = <String>[];
    Widget scoped(String language, {bool offline = false}) {
      return DictationScope(
        service: speech,
        languageTag: language,
        onDeviceOnly: offline,
        child: Builder(
          builder: (BuildContext context) {
            final DictationScope scope = DictationScope.maybeOf(context)!;
            seen.add('${scope.languageTag}:${scope.onDeviceOnly}');
            return const SizedBox.shrink();
          },
        ),
      );
    }

    await tester.pumpWidget(scoped('en'));
    await tester.pumpWidget(scoped('lg'));
    await tester.pumpWidget(scoped('lg', offline: true));
    expect(seen, <String>['en:false', 'lg:false', 'lg:true']);
  });
}
