import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/log_export.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Last-resort screen the top-level error boundary shows for a build failure.
///
/// Restart remounts the failed subtree under the existing provider scope.
/// Export writes the redacted log. The recycle bin is offered. Nothing on
/// this screen deletes, purges or resets work (FE-SIMP-09, FE-SEC-08).
class GlobalErrorPage extends ConsumerWidget {
  /// Creates the recovery screen for [failure].
  const GlobalErrorPage({
    super.key,
    required this.failure,
    required this.onRestart,
    required this.onOpenRecycleBin,
    this.exportDirectory,
    this.shareFile,
    this.writeLog,
  });

  /// The typed failure to explain. Copy comes from here, not this page
  /// (FE-CONS-11).
  final Failure failure;

  /// Remounts the failed subtree. Does not create a new [ProviderScope].
  final VoidCallback onRestart;

  /// Opens restored records. Until task 168 the shell sends this to More.
  final VoidCallback onOpenRecycleBin;

  /// Folder [exportLog] writes into. Tests pass a temp directory so the
  /// suite never touches the platform documents tree (FE-TEST-03).
  final Directory? exportDirectory;

  /// Hands the exported file to the platform share sheet. Tests replace
  /// this so they never open a sheet. No share package is on the allowlist
  /// (FE-FLOW-06); the file on disk is the shareable artefact.
  final Future<void> Function(File file)? shareFile;

  /// Writes the current logger buffer. Tests pass a synchronous writer
  /// because `dart:io` futures do not complete under the widget-test
  /// fake async clock.
  final Future<Result<File>> Function(Directory into)? writeLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool exporting = ref.watch(_exportBusyProvider);
    return AppPage(
      title: Copy.somethingWentWrong,
      subtitle: Copy.workStillOnDevice,
      body: AppErrorState(failure: failure),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppPrimaryAction(label: Copy.restart, onPressed: onRestart),
          const SizedBox(height: Space.x2),
          AppButton(
            label: Copy.exportLog,
            variant: AppButtonVariant.secondary,
            busy: exporting,
            onPressed: () {
              // The notifier's busy flag owns this future (FE-CODE-07).
              unawaited(
                ref
                    .read(_exportBusyProvider.notifier)
                    .run(
                      into: exportDirectory ?? Directory.systemTemp,
                      share: shareFile ?? _keepFileOnDisk,
                      writeLog: writeLog ?? _writeLog,
                    ),
              );
            },
          ),
          const SizedBox(height: Space.x2),
          AppButton(
            label: Copy.openRecycleBin,
            variant: AppButtonVariant.text,
            onPressed: onOpenRecycleBin,
          ),
        ],
      ),
    );
  }
}

/// Share is a later plugin. The export already wrote a shareable file.
Future<void> _keepFileOnDisk(File _) async {}

Future<Result<File>> _writeLog(Directory into) => exportLog(into: into);

final NotifierProvider<_ExportBusy, bool> _exportBusyProvider =
    NotifierProvider<_ExportBusy, bool>(_ExportBusy.new);

class _ExportBusy extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> run({
    required Directory into,
    required Future<void> Function(File file) share,
    required Future<Result<File>> Function(Directory into) writeLog,
  }) async {
    if (state) {
      return;
    }
    state = true;
    try {
      final Result<File> result = await writeLog(into);
      final File? file = result.fold(
        (Failure _) => null,
        (File value) => value,
      );
      if (file != null) {
        await share(file);
      }
    } finally {
      state = false;
    }
  }
}
