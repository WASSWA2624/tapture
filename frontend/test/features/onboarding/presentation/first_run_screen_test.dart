import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/onboarding/presentation/first_run_screen.dart';

void main() {
  testWidgets('skipping stores the name and opens capture', (
    WidgetTester tester,
  ) async {
    final Map<String, String> backing = <String, String>{};
    final ProviderContainer container = await _pump(tester, backing);

    expect(find.byType(FirstRunScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.pump();
    await tester.tap(find.text(Copy.firstRunSkip));
    await tester.pumpAndSettle();

    expect(find.byType(FirstRunScreen), findsNothing);
    expect(find.byKey(const ValueKey<String>('route-capture')), findsOneWidget);
    expect(container.read(routerProvider).state.uri.path, '/capture');
    expect(container.read(firstRunProvider).completed, isTrue);
    expect(container.read(firstRunProvider).name, 'Ada');
    expect(container.read(firstRunProvider).startProject, isFalse);
    expect(backing[AppConstants.preferences.firstRun], contains('completed=1'));
    expect(
      backing[AppConstants.preferences.firstRun],
      contains('startProject=0'),
    );
  });

  testWidgets('starting a project uses a shipped template and opens capture', (
    WidgetTester tester,
  ) async {
    final Map<String, String> backing = <String, String>{};
    final ProviderContainer container = await _pump(tester, backing);

    await tester.enterText(find.byType(TextField), 'Bea');
    await tester.pump();
    await tester.tap(find.text(Copy.firstRunStartProject));
    await tester.pumpAndSettle();

    expect(find.byType(FirstRunScreen), findsNothing);
    expect(find.byKey(const ValueKey<String>('route-capture')), findsOneWidget);
    expect(container.read(routerProvider).state.uri.path, '/capture');
    expect(container.read(firstRunProvider).completed, isTrue);
    expect(container.read(firstRunProvider).name, 'Bea');
    expect(container.read(firstRunProvider).startProject, isTrue);
    expect(
      backing[AppConstants.preferences.firstRun],
      contains('startProject=1'),
    );
  });

  testWidgets('a completed flag skips the screen on a second launch', (
    WidgetTester tester,
  ) async {
    final Map<String, String> backing = <String, String>{};
    await _pump(tester, backing);
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.pump();
    await tester.tap(find.text(Copy.firstRunSkip));
    await tester.pumpAndSettle();

    await _pump(tester, backing, key: const ValueKey<String>('second-launch'));

    expect(find.byType(FirstRunScreen), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('route-projects')),
      findsOneWidget,
    );
    expect(find.text(Copy.firstRunTitle), findsNothing);
  });
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Map<String, String> backing, {
  Key? key,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: key,
      overrides: [firstRunOverride(backing)],
      child: const TaptureApp(),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(TaptureApp)));
}
