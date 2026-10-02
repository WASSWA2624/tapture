import 'dart:async';
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/router.dart' show routerProvider;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/features/records/domain/record_entry.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;

/// Measures the production record grid on an explicitly selected native runner.
/// The caller owns a real seeded record, files, database and app container.
/// Host widget pumps cannot supply native frame evidence for this scenario.
Future<Map<String, Object?>> measureDevicePhotoGrid(
  WidgetTester tester, {
  required ProviderContainer container,
  required String recordId,
}) async {
  if (kIsWeb || tester.binding is! LiveTestWidgetsFlutterBinding) {
    throw TestFailure(
      'The photo-grid device metric requires a live native runner.',
    );
  }
  if (container.read(thumbnailsFromBytesProvider)) {
    throw TestFailure(
      'The native photo-grid fixture must use real cached thumbnail files.',
    );
  }
  final double refreshRate = tester.view.display.refreshRate;
  if (!refreshRate.isFinite || refreshRate <= 0) {
    throw TestFailure('The native display refresh rate is unavailable.');
  }
  final int frameBudget = (Duration.microsecondsPerSecond / refreshRate).ceil();
  final Duration framePeriod = Duration(microseconds: frameBudget);
  final RecordEntry? record =
      (await container.read(recordRepositoryProvider).byId(recordId)).fold(
        (Failure failure) => throw TestFailure(failure.message),
        (RecordEntry? value) => value,
      );
  if (record == null || record.photos.length != 2000) {
    throw TestFailure(
      'The device photo-grid record must contain exactly 2,000 live photos.',
    );
  }
  final Directory root = (await container.read(storageRootProvider).resolve())
      .fold(
        (Failure failure) => throw TestFailure(failure.message),
        (Directory value) => value,
      );
  expect(
    record.photos.map((photo) => photo.storagePath).toSet(),
    hasLength(2000),
  );
  for (final photo in record.photos) {
    expect(
      await File('${root.path}/${photo.storagePath}').length(),
      greaterThan(0),
      reason: 'The native frame fixture requires each original file on disk.',
    );
  }
  container
      .read(routerProvider)
      .go(RoutePaths.projectRecord(record.projectId, record.id));
  await tester.pumpAndSettle();
  final Finder grid = find.byKey(
    const ValueKey<String>('record-detail-scroll'),
  );
  expect(grid, findsOneWidget);
  final ScrollPosition position = tester
      .state<ScrollableState>(
        find.descendant(of: grid, matching: find.byType(Scrollable)),
      )
      .position;
  final SliverGridDelegateWithFixedCrossAxisCount delegate =
      tester
              .widget<SliverGrid>(
                find.descendant(of: grid, matching: find.byType(SliverGrid)),
              )
              .gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
  final int mountedBound =
      ((position.viewportDimension +
                      2 * RenderAbstractViewport.defaultCacheExtent) /
                  (delegate.mainAxisExtent! + delegate.mainAxisSpacing))
              .ceil() *
          delegate.crossAxisCount +
      2 * delegate.crossAxisCount;
  final double end = position.maxScrollExtent;
  final Map<int, FrameTiming> measuredFrames = <int, FrameTiming>{};
  int latestReported = -1;
  int? measuredAfter;
  int? awaitedFrame;
  Completer<void>? arrived;
  void onTimings(List<FrameTiming> frames) {
    for (final FrameTiming frame in frames) {
      if (frame.frameNumber > latestReported) {
        latestReported = frame.frameNumber;
      }
      final int? boundary = measuredAfter;
      if (boundary != null && frame.frameNumber > boundary) {
        measuredFrames[frame.frameNumber] = frame;
      }
    }
    final int? target = awaitedFrame;
    final Completer<void>? pending = arrived;
    if (target != null &&
        pending != null &&
        latestReported >= target &&
        !pending.isCompleted) {
      pending.complete();
    }
  }

  Future<void> waitForFrame(int target) async {
    if (target < 0) {
      throw TestFailure('The native engine frame identity is unavailable.');
    }
    if (latestReported >= target) return;
    awaitedFrame = target;
    final Completer<void> ready = Completer<void>();
    arrived = ready;
    try {
      await ready.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TestFailure('The engine did not report native frame $target.');
        },
      );
    } finally {
      awaitedFrame = null;
      arrived = null;
    }
  }

  tester.binding.addTimingsCallback(onTimings);
  int mostMounted = 0;
  try {
    for (final double fraction in <double>[0.5, 0.25, 0]) {
      position.jumpTo(end * fraction);
      await tester.pumpAndSettle();
    }
    // Frame identities separate the completed warm-up batch from measurement.
    final int warmUpFrame = tester.platformDispatcher.frameData.frameNumber;
    await waitForFrame(warmUpFrame);
    measuredAfter = warmUpFrame;
    for (int station = 0; station < 20; station++) {
      position.jumpTo(end * station / 20);
      await tester.pump();
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(grid),
      );
      try {
        for (int step = 0; step < 12; step++) {
          await gesture.moveBy(const Offset(0, -48));
          await tester.pump(framePeriod);
          final int mounted = find
              .descendant(of: grid, matching: find.byType(RecordThumb))
              .evaluate()
              .length;
          if (mounted > mostMounted) mostMounted = mounted;
        }
      } finally {
        await gesture.up();
      }
    }
    position.jumpTo(end);
    await tester.pumpAndSettle();
    await waitForFrame(tester.platformDispatcher.frameData.frameNumber);
  } finally {
    tester.binding.removeTimingsCallback(onTimings);
  }
  final List<FrameTiming> timings = measuredFrames.values.toList();
  expect(
    timings.length,
    greaterThanOrEqualTo(20),
    reason:
        'The 20 scroll stations require distinct actual engine FrameTiming samples.',
  );
  final List<int> builds =
      timings
          .map((FrameTiming frame) => frame.buildDuration.inMicroseconds)
          .toList()
        ..sort();
  final List<int> rasters =
      timings
          .map((FrameTiming frame) => frame.rasterDuration.inMicroseconds)
          .toList()
        ..sort();
  final List<int> totals =
      timings
          .map((FrameTiming frame) => frame.totalSpan.inMicroseconds)
          .toList()
        ..sort();
  int p90(List<int> values) => values[(values.length * 0.9).ceil() - 1];
  final Map<String, Object?> evidence = <String, Object?>{
    'photos': record.photos.length,
    'frames': timings.length,
    'warmUpFrame': measuredAfter,
    'lastReportedFrame': latestReported,
    'refreshRateHz': refreshRate,
    'frameBudgetMicros': frameBudget,
    'buildP90Micros': p90(builds),
    'rasterP90Micros': p90(rasters),
    'totalSpanP90Micros': p90(totals),
    'worstBuildMicros': builds.last,
    'worstRasterMicros': rasters.last,
    'maxMountedThumbnails': mostMounted,
    'viewportThumbnailBound': mountedBound,
  };
  expect(p90(builds), lessThanOrEqualTo(frameBudget), reason: '$evidence');
  expect(p90(rasters), lessThanOrEqualTo(frameBudget), reason: '$evidence');
  expect(mostMounted, lessThanOrEqualTo(mountedBound), reason: '$evidence');
  expect(tester.takeException(), isNull);
  return evidence;
}
