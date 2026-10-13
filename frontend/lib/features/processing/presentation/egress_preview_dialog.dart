import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

import '../domain/processing_job.dart';
import 'processing_controller.dart';

/// The shared consent preview for a project, record or field processing run.
Future<bool> confirmProcessingEgress(
  BuildContext context,
  ProviderContainer container,
  ProcessingJob job,
) async {
  if (!context.mounted) return false;
  final summary = await container.read(processingEgressSummaryProvider)(job);
  if (!context.mounted) return false;
  final String identity = await container.read(
    processingEgressIdentityProvider,
  )(job);
  if (summary.imageCount == 0 && summary.payloadBytes == 0) return true;
  if (!context.mounted) return false;
  return showEgressPreview(
    context,
    imageCount: summary.imageCount,
    payloadBytes: summary.payloadBytes,
    selectionDetails: _selectionDetails(identity, Copy.of(context)),
  );
}

String? _selectionDetails(String identity, LocalizedCopy copy) {
  if (identity.isEmpty) return null;
  final Object? decoded = jsonDecode(identity);
  if (decoded is! Map<String, Object?>) return null;
  final Object? entries = decoded['selections'];
  if (entries is! List<Object?>) return null;
  final Object? cost = decoded['maxCost'];
  final String limit = cost is num && cost > 0
      ? cost.toString()
      : copy.processingEgressLimitDefault;
  return <String>{
    for (final Object? entry in entries)
      if (entry is Map<String, Object?>)
        copy.processingEgressSelection(
          entry['provider']?.toString() ?? '',
          entry['model']?.toString() ?? '',
          entry['personal'] == true
              ? copy.processingEgressPersonal
              : copy.processingEgressManaged,
          limit,
        ),
  }.join('\n');
}

/// Asks, with the shared confirm dialog, before the session's first online
/// call, naming what would leave the device. Cancel, Back or a tap outside
/// answers false and keeps the session offline.
Future<bool> showEgressPreview(
  BuildContext context, {
  required int imageCount,
  required int payloadBytes,
  String? selectionDetails,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppConfirm(
    context,
    title: localCopy.egressTitle,
    message: <String>[
      localCopy.egressBody(
        images: imageCount,
        size: localCopy.fileSize(payloadBytes),
      ),
      if (selectionDetails != null && selectionDetails.isNotEmpty)
        selectionDetails,
    ].join('\n\n'),
    confirmLabel: localCopy.egressSend,
  );
}
