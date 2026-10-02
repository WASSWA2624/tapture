import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_worker_secrets.dart';
import 'worker_cloud_destination.dart';

/// Browser stand-in. Production cloud destinations are native-only.
Future<Result<Uri>> sendOnWorker(
  CloudWorkerJob job, {
  void Function(int sent, int total)? onProgress,
  CancellationToken? cancel,
  required Future<Result<void>> Function(CloudSecretWrite write) persist,
  Result<void> Function()? permit,
  Future<Result<String>> Function(String invalidToken)? refreshNative,
  Duration? checkpointTimeout,
}) => job
    .build(CloudWorkerSecrets(job, persist))
    .send(
      job.destination,
      job.file,
      remoteName: job.remoteName,
      offset: job.offset,
      onProgress: onProgress,
      cancel: cancel,
    );
