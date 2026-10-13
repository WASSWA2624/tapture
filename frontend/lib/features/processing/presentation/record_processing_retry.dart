import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

import 'processing_findings_providers.dart';

/// Confirms an uncertain prior charge before any retry generation is written.
/// Success contains whether explicit charge approval was needed and given.
Future<Result<bool>> confirmRecordProcessingRetry(
  BuildContext context,
  ProviderContainer container,
  String recordId,
) async {
  final Result<bool> approval = await container
      .read(processingFindingsStoreProvider)
      .requiresRecordRetryApproval(recordId);
  if (!context.mounted) return const FailureResult<bool>(CancelledFailure());
  if (approval is FailureResult<bool>) return approval;
  if (!(approval as Success<bool>).value) return const Success<bool>(false);
  final bool accepted = await showAppConfirm(
    context,
    title: Copy.of(context).processingRetryChargeTitle,
    message: Copy.of(context).processingRetryChargeBody,
    confirmLabel: Copy.of(context).processingRetryChargeConfirm,
  );
  return accepted && context.mounted
      ? const Success<bool>(true)
      : const FailureResult<bool>(CancelledFailure());
}
