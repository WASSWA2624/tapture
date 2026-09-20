import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import '../domain/project_openable_file_lookup.dart';
import '../domain/project_repository.dart';

/// Hands a cache copy of a project's file to another app, or downloads it.
class ProjectOpenExternallyAction {
  /// Looks up the file and hands a copy off. Failures render [AppErrorState].
  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final Result<ProjectOpenableFile?> found = await ref
        .read(projectOpenableFileLookupProvider)
        .find(projectId: project.id, folderName: project.folderName);
    if (!context.mounted) {
      return;
    }
    switch (found) {
      case FailureResult<ProjectOpenableFile?>(:final Failure failure):
        await _showFailure(context, failure);
        return;
      case Success<ProjectOpenableFile?>(:final ProjectOpenableFile? value):
        if (value == null) {
          await _showFailure(context, projectNothingToOpenFailure());
          return;
        }
        final Result<void> handed = await ref
            .read(downloadServiceProvider)
            .openExternally(
              fileName: value.fileName,
              bytes: value.bytes,
              mimeType: value.mimeType,
            );
        if (!context.mounted) {
          return;
        }
        switch (handed) {
          case FailureResult<void>(:final Failure failure):
            await _showFailure(context, failure);
          case Success<void>():
            break;
        }
    }
  }
}

/// Lookup used by the list and the home. Tests keep the fake; [main] swaps
/// in the platform reader.
final Provider<ProjectOpenableFileLookup> projectOpenableFileLookupProvider =
    Provider<ProjectOpenableFileLookup>((Ref _) {
      return ProjectOpenableFileLookup.fake();
    });

/// Whether the project row or home should offer Open with.
final projectHasOpenableFileProvider =
    FutureProvider.family<bool, ({String projectId, String folderName})>((
      Ref ref,
      ({String projectId, String folderName}) key,
    ) async {
      final Result<bool> present = await ref
          .watch(projectOpenableFileLookupProvider)
          .exists(projectId: key.projectId, folderName: key.folderName);
      return present.fold((Failure _) => false, (bool value) => value);
    }, retry: (int _, Object _) => null);

/// Open with, or Download a copy on the web, when the platform can hand a
/// file off and the project has one. Null hides the row.
AppOverflowAction? projectOpenExternallyMenuItem(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  final DownloadService downloads = ref.watch(downloadServiceProvider);
  if (!downloads.canOpenExternally && !downloads.canDownloadCopy) {
    return null;
  }
  final AsyncValue<bool> present = ref.watch(
    projectHasOpenableFileProvider((
      projectId: project.id,
      folderName: project.folderName,
    )),
  );
  if (!present.hasValue || present.requireValue != true) {
    return null;
  }
  final bool openWith = downloads.canOpenExternally;
  return AppOverflowAction(
    key: ValueKey<String>('project-open-${project.id}'),
    label: openWith ? Copy.projectOpenWith : Copy.projectDownloadCopy,
    icon: openWith ? Icons.open_in_new : Icons.download_outlined,
    onTap: () =>
        unawaited(ProjectOpenExternallyAction.open(context, ref, project)),
  );
}

Future<void> _showFailure(BuildContext context, Failure failure) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AppDialog.confirm(
        title: Copy.projectOpenFailedTitle,
        message: failure.message,
        confirmLabel: Copy.ok,
        extra: AppErrorState(failure: failure),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
        },
      );
    },
  );
}
