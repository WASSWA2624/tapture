import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'bundle_output.dart';
import 'bundle_zip_job.dart';

/// Used when neither `dart:io` nor the web library is available.
Future<Result<BundleOutput>> zipBundle(BundleZipJob job) async {
  return FailureResult<BundleOutput>(
    StorageFailure(
      localizedMessage: Copy.messages.packageWriteFailed,
      localizedRecovery: Copy.messages.tryAgain,
    ),
  );
}
