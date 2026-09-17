import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/provider_observer.dart' hide ProviderObserver;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/main.dart' as app;

void main() {
  late Logger previous;

  setUp(() {
    previous = Logger.current;
    Env.debugFlavor = Flavor.dev;
  });

  tearDown(() {
    Logger.current = previous;
    Env.debugFlavor = null;
  });

  test('a provider that throws produces exactly one logged error', () {
    final Logger logger = Logger();
    final ProviderContainer container = ProviderContainer(
      observers: <ProviderObserver>[AppProviderObserver(logger)],
      retry: (int _, Object _) => null,
    );
    addTearDown(container.dispose);

    final Provider<int> failingProvider = Provider<int>(
      (Ref _) => throw StateError('boom'),
      name: 'failing',
    );

    Object? thrown;
    try {
      container.read(failingProvider);
    } on Object catch (error) {
      thrown = error;
    }
    expect(thrown, isNotNull);

    final List<String> errors = logger.buffer
        .where((String line) => line.contains('\terror\t'))
        .toList();
    expect(errors, hasLength(1));
    expect(errors.single, contains('failing'));
  });

  test('rebuilds above the threshold are recorded once', () {
    final Logger logger = Logger();
    final ProviderContainer container = ProviderContainer(
      observers: <ProviderObserver>[AppProviderObserver(logger)],
      retry: (int _, Object _) => null,
    );
    addTearDown(container.dispose);

    final NotifierProvider<_Counter, int> counterProvider =
        NotifierProvider<_Counter, int>(_Counter.new, name: 'counter');

    container.read(counterProvider);
    final int over = AppConstants.logging.rebuildThreshold + 1;
    for (int index = 0; index < over; index++) {
      container.read(counterProvider.notifier).bump();
    }

    final List<String> warnings = logger.buffer
        .where((String line) => line.contains('\twarn\t'))
        .toList();
    expect(warnings, hasLength(1));
    expect(warnings.single, contains('counter'));
    expect(warnings.single, contains('$over'));
  });

  testWidgets('the observer is absent from a production build', (
    WidgetTester tester,
  ) async {
    Env.debugFlavor = Flavor.prod;
    await app.main();
    await tester.pump();

    final ProviderScope scope = tester.widget(find.byType(ProviderScope));
    expect(scope.observers, isEmpty);
    expect(find.byType(TaptureApp), findsOneWidget);
  });

  testWidgets('the observer is installed in a development build', (
    WidgetTester tester,
  ) async {
    Env.debugFlavor = Flavor.dev;
    await app.main();
    await tester.pump();

    final ProviderScope scope = tester.widget(find.byType(ProviderScope));
    expect(scope.observers, isNotEmpty);
    expect(scope.observers!.single, isA<AppProviderObserver>());
  });
}

final class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
