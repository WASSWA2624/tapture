import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Last-resort screen the top-level error boundary shows for a build failure.
///
/// Restart remounts the failed subtree under the existing provider scope.
/// Export saves the redacted log where the person can open it, and says
/// where it went. The recycle bin is offered. Nothing on this screen
/// deletes, purges or resets work (FE-SIMP-09, FE-SEC-08).
class GlobalErrorPage extends ConsumerWidget {
  /// Creates the recovery screen for [failure].
  const GlobalErrorPage({
    super.key,
    required this.failure,
    required this.onRestart,
    required this.onOpenRecycleBin,
  });

  /// The typed failure to explain. Copy comes from here, not this page
  /// (FE-CONS-11).
  final Failure failure;

  /// Remounts the failed subtree. Does not create a new [ProviderScope].
  final VoidCallback onRestart;

  /// Opens the recycle bin.
  final VoidCallback onOpenRecycleBin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool exporting = ref.watch(_exportBusyProvider);
    return AppPage(
      title: localCopy.somethingWentWrong,
      subtitle: localCopy.workStillOnDevice,
      body: AppErrorState(failure: failure),
      // One row that wraps only when it must. Restart is the one filled
      // action (FE-SIMP-01); the other two are outlined, so all three align.
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.x2,
        runSpacing: Space.x2,
        children: <Widget>[
          AppButton(
            key: const ValueKey<String>('global-error-restart'),
            label: localCopy.restart,
            onPressed: onRestart,
          ),
          AppButton(
            key: const ValueKey<String>('global-error-export'),
            label: localCopy.exportLog,
            variant: AppButtonVariant.secondary,
            busy: exporting,
            onPressed: () {
              // The notifier's busy flag owns this future (FE-CODE-07).
              unawaited(_export(context, ref));
            },
          ),
          AppButton(
            label: localCopy.openRecycleBin,
            variant: AppButtonVariant.secondary,
            onPressed: onOpenRecycleBin,
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<String?>? saved = await ref
        .read(_exportBusyProvider.notifier)
        .run(ref.read(downloadServiceProvider));
    if (saved == null || !context.mounted) {
      return;
    }
    switch (saved) {
      case Success<String?>(:final String? value):
        showAppSnack(
          context,
          value == null
              ? localCopy.feedbackDownloadStarted
              : localCopy.feedbackDownloadedTo(value),
          tone: SnackTone.success,
        );
      case FailureResult<String?>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.warning,
          localizedMessage: failure.explanation,
        );
    }
  }
}

/// MIME type of the exported log.
const String _logMimeType = 'text/plain';

final NotifierProvider<_ExportBusy, bool> _exportBusyProvider =
    NotifierProvider<_ExportBusy, bool>(_ExportBusy.new);

class _ExportBusy extends Notifier<bool> {
  @override
  bool build() => false;

  /// Saves the logger's redacted buffer through [downloads]: a browser
  /// download on the web, `Downloads/Tapture` elsewhere. Null while a
  /// previous export is still running.
  Future<Result<String?>?> run(DownloadService downloads) async {
    if (state) {
      return null;
    }
    state = true;
    try {
      final Logger logger = Logger.current;
      return await downloads.save(
        fileName: logger.exportFileName,
        bytes: utf8.encode(logger.buffer.join('\n')),
        mimeType: _logMimeType,
      );
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }
}
