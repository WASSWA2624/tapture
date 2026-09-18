import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';

void main() {
  test('pause awaits the flush', () async {
    final Completer<void> started = Completer<void>();
    final Completer<void> release = Completer<void>();
    var flushed = false;
    final LifecycleObserver observer = LifecycleObserver.fake(
      onPauseFlush: () async {
        started.complete();
        await release.future;
        flushed = true;
      },
    );

    final Future<void> paused = observer.handle(AppLifecycleState.paused);
    await started.future;
    expect(flushed, isFalse);

    release.complete();
    await paused;
    expect(flushed, isTrue);
  });

  test('resume notifies listeners', () async {
    final LifecycleObserver observer = LifecycleObserver.fake();
    final List<AppLifecycleState> seen = <AppLifecycleState>[];
    final StreamSubscription<AppLifecycleState> subscription = observer.states
        .listen(seen.add);
    addTearDown(subscription.cancel);

    await observer.handle(AppLifecycleState.resumed);

    expect(seen, <AppLifecycleState>[AppLifecycleState.resumed]);
  });

  test('a second pause does not flush twice before resume', () async {
    var flushes = 0;
    final LifecycleObserver observer = LifecycleObserver.fake(
      onPauseFlush: () async {
        flushes += 1;
      },
    );

    await observer.handle(AppLifecycleState.hidden);
    await observer.handle(AppLifecycleState.paused);
    expect(flushes, 1);

    await observer.handle(AppLifecycleState.resumed);
    await observer.handle(AppLifecycleState.paused);
    expect(flushes, 2);
  });

  test('exit with no checks proceeds', () async {
    expect(
      await LifecycleObserver.fake().didRequestAppExit(),
      AppExitResponse.exit,
    );
  });

  test('a false check cancels exit', () async {
    final LifecycleObserver observer = LifecycleObserver.fake()
      ..addExitCheck(() async => false);
    expect(await observer.didRequestAppExit(), AppExitResponse.cancel);
  });

  test('a removed check no longer runs', () async {
    Future<bool> deny() async => false;
    final LifecycleObserver observer = LifecycleObserver.fake()
      ..addExitCheck(deny)
      ..removeExitCheck(deny);
    expect(await observer.didRequestAppExit(), AppExitResponse.exit);
  });
}
