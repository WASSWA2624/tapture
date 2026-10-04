import 'dart:ui' show RootIsolateToken;

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'worker_isolate.dart';
import 'worker_port.dart';

/// The web has no isolate to count.
int get debugLiveWorkers => 0;

/// The web cannot host a long-lived worker isolate.
Future<Result<WorkerIsolate>> spawnWorker<A>(
  Future<void> Function(WorkerPort port, A argument) entry,
  A argument, {
  required String debugName,
  Duration? startTimeout,
  RootIsolateToken? platformToken,
  Future<Result<Object?>> Function(Object? question)? answer,
}) async => const FailureResult<WorkerIsolate>(
  ProviderFailure(kind: ProviderFailureKind.unavailable),
);
