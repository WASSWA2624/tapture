@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart';

import 'support/device_capture_metric.dart';
import 'support/device_metric_bootstrap.dart';
import 'support/device_package_metric.dart';
import 'support/device_photo_grid_fixture.dart';
import 'support/device_photo_grid_metric.dart';

void main() {
  if (!const bool.fromEnvironment('TAPTURE_DEVICE_METRICS')) {
    test(
      'native physical-device metrics require explicit opt-in',
      () {},
      skip:
          'Pass --profile --dart-define=TAPTURE_DEVICE_METRICS=true on a physical Android/iOS device.',
    );
    return;
  }
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'owned native production bootstrap, shutter, export, merge and photo grid',
    (WidgetTester tester) async {
      if (!Platform.isAndroid && !Platform.isIOS) {
        throw TestFailure(
          'Device setup required: physical Android/iOS; desktop cannot produce camera acceptance.',
        );
      }
      if (!kProfileMode) {
        throw TestFailure(
          'Device setup required: --profile, so debug overhead cannot certify device budgets.',
        );
      }
      final List<Map<String, Object?>> metrics = <Map<String, Object?>>[];
      void emit(Map<String, Object?> metric) {
        metrics.add(metric);
        // The device-matrix runner consumes these exact measured durations.
        // ignore: avoid_print
        print('TAPTURE_METRIC ${jsonEncode(metric)}');
      }

      final DeviceMetricBootstrap fixture =
          await DeviceMetricBootstrap.create();
      DevicePackageMetric? receiver;
      try {
        final Stopwatch cold = Stopwatch()..start();
        await fixture.start();
        ProviderContainer? container;
        await _until(tester, () {
          final Finder route = find.byKey(
            const ValueKey<String>('route-projects'),
          );
          if (route.evaluate().isEmpty) return false;
          container = ProviderScope.containerOf(tester.element(route));
          return container!.read(projectListProvider).hasValue &&
              find
                  .byWidgetPredicate(
                    (Widget widget) =>
                        widget is AppButton &&
                        widget.label == Copy.projectsCreate &&
                        widget.onPressed != null &&
                        !widget.busy,
                  )
                  .hitTestable()
                  .evaluate()
                  .isNotEmpty;
        }, 'app bootstrap to a usable Projects frame');
        cold.stop();
        emit(<String, Object?>{
          'metric': 'coldStart',
          'milliseconds': cold.elapsedMilliseconds,
          'scope':
              'app bootstrap to usable Projects frame; excludes OS process launch, instrumentation binding and sandbox allocation',
          'runMode': 'profile',
          'platform': Platform.operatingSystem,
        });
        final ProviderContainer providers = container!;
        expect(
          providers.read(recordRepositoryProvider),
          isA<RecordRepositoryImpl>(),
        );
        final ExportRepository exports = providers.read(
          exportRepositoryProvider,
        )!;
        expect(exports, isA<ExportRepositoryImpl>());
        final Project project =
            (await providers
                    .read(projectRepositoryProvider)
                    .createReady(name: 'Device measurement'))
                .getOrThrow();
        final TemplateDef template =
            (await providers
                    .read(templateRepositoryProvider)
                    .save(
                      TemplateDef(
                        id: '',
                        templateKey: 'device_metric_records',
                        name: 'Device metric records',
                        version: 1,
                        projectId: project.id,
                        fields: const <FieldDef>[
                          FieldDef(
                            fieldKey: 'serial',
                            label: 'Serial',
                            type: FieldType.text,
                            identity: true,
                          ),
                          FieldDef(
                            fieldKey: 'note',
                            label: 'Note',
                            type: FieldType.text,
                          ),
                        ],
                        identityFieldKeys: const <String>['serial'],
                        rows: const <TemplateRow>[],
                      ),
                    ))
                .getOrThrow();
        final baseline = await exportDevicePackage(
          exports,
          fixture.root,
          project.id,
        );
        receiver = await DevicePackageMetric.create(
          directory: fixture.directory,
          baseline: baseline,
        );
        emit(
          await measureDeviceShutter(
            tester,
            container: providers,
            database: fixture.database,
            project: project,
            templateId: template.id,
            root: fixture.root,
          ),
        );
        final RecordRepository records = providers.read(
          recordRepositoryProvider,
        );
        for (int index = 1; index < 1000; index++) {
          (await records.save((
            projectId: project.id,
            templateId: template.id,
            fields: <String, String>{
              'serial': 'metric-$index',
              'note': 'Owned native measurement row $index',
            },
            context: <String, String>{},
          ))).getOrThrow();
        }
        final full = await exportDevicePackage(
          exports,
          fixture.root,
          project.id,
          measured: emit,
        );
        emit(await receiver.measureMerge(full, project.id));
        final String gridRecord = await seedDevicePhotoGrid(
          container: providers,
          database: fixture.database,
          root: fixture.root,
          project: project,
          templateId: template.id,
        );
        final Map<String, Object?> frames = await measureDevicePhotoGrid(
          tester,
          container: providers,
          recordId: gridRecord,
        );
        binding.reportData = <String, Object?>{
          'durations': metrics,
          'photoGrid': frames,
          'runMode': 'profile',
          'platform': Platform.operatingSystem,
        };
        // Kept separate from the four duration budgets consumed by the runner.
        // ignore: avoid_print
        print('TAPTURE_FRAME_METRIC ${jsonEncode(frames)}');
        expect(tester.takeException(), isNull);
      } finally {
        await receiver?.close();
        await tester.pumpWidget(const SizedBox.shrink());
        await fixture.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

Future<void> _until(
  WidgetTester tester,
  bool Function() ready,
  String requirement,
) async {
  final Stopwatch deadline = Stopwatch()..start();
  while (!ready()) {
    if (deadline.elapsed > const Duration(seconds: 30)) {
      throw TestFailure('Device readiness failed: $requirement.');
    }
    await tester.pump(const Duration(milliseconds: 16));
  }
}
