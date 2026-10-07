import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flushes widget microtasks and worker events until an external operation lands.
/// Both queues must advance when a route transition starts an isolate job.
Future<void> pumpExternalWork(
  WidgetTester tester,
  bool Function() completed,
) async {
  final Stopwatch elapsed = Stopwatch()..start();
  while (!completed()) {
    if (elapsed.elapsed > const Duration(seconds: 10)) {
      throw TestFailure('External widget work did not complete.');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Advances both clocks while awaiting futures started from widget callbacks.
/// Awaiting them inside `runAsync` alone can deadlock their fake-zone callbacks.
Future<void> pumpExternalFutures(
  WidgetTester tester,
  Iterable<Future<Object?>> futures,
) async {
  final List<Future<Object?>> pending = futures.toList();
  int completed = 0;
  (Object, StackTrace)? failure;
  for (final Future<Object?> future in pending) {
    future.then<void>(
      (_) => completed++,
      onError: (Object error, StackTrace stack) {
        failure ??= (error, stack);
        completed++;
      },
    );
  }
  await pumpExternalWork(tester, () => completed == pending.length);
  if (failure case (final Object error, final StackTrace stack)) {
    Error.throwWithStackTrace(error, stack);
  }
}

/// Lands the file-existence checks a thumbnail makes before it draws.
/// [AppPhotoThumb] reads them through a `FutureBuilder<bool>` off the fake
/// clock, so a plain pump leaves every thumb undecided.
Future<void> pumpThumbnailChecks(WidgetTester tester) async {
  await tester.pump();
  await pumpExternalFutures(
    tester,
    tester
        .widgetList<FutureBuilder<bool>>(find.byType(FutureBuilder<bool>))
        .map((FutureBuilder<bool> availability) => availability.future!),
  );
}
