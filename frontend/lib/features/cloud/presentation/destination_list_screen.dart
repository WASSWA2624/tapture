import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../data/destination_repository_impl.dart';

/// Lists configured destinations and refuses to save one whose test failed.
final class DestinationListScreen extends ConsumerWidget {
  /// Creates the list. Passing [rows] skips the store, for tests.
  const DestinationListScreen({
    this.rows,
    this.loading = false,
    this.failure,
    this.editing = false,
    this.labelController,
    this.folderController,
    this.secretController,
    this.onCheck,
    this.onSave,
    this.onRemove,
    super.key,
  });

  /// Destinations to show. Null watches the store.
  final List<Destination>? rows;

  /// Whether the list is still loading.
  final bool loading;

  /// Why the list could not be read.
  final Failure? failure;

  /// Whether the add form is open.
  final bool editing;

  /// Name field. Empty after a successful save.
  final TextEditingController? labelController;

  /// Folder field.
  final TextEditingController? folderController;

  /// Sign-in field. Obscured, and cleared after a successful save.
  final TextEditingController? secretController;

  /// Probe upload. False means the destination is not saved.
  final Future<bool> Function()? onCheck;

  /// Called only after [onCheck] succeeds.
  final VoidCallback? onSave;

  /// Removes one destination after the person confirms.
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.destinationTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return const AppPage(title: Copy.destinationTitle, body: AppSkeleton());
    }
    final List<Destination>? injected = rows;
    if (injected == null) {
      final AsyncValue<List<Destination>> async = ref.watch(
        _destinationListProvider,
      );
      return async.when(
        loading: () =>
            const AppPage(title: Copy.destinationTitle, body: AppSkeleton()),
        error: (Object error, StackTrace _) => AppPage(
          title: Copy.destinationTitle,
          body: AppErrorState(
            failure: error is Failure
                ? error
                : const StorageFailure(
                    message: 'The destinations could not be read.',
                    recoveryAction: 'Try again.',
                  ),
          ),
        ),
        data: (List<Destination> loaded) => _page(loaded),
      );
    }
    return _page(injected);
  }

  Widget _page(List<Destination> loaded) {
    final TextEditingController? secret = secretController;
    return AppPage(
      title: Copy.destinationTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (loaded.isEmpty)
            const AppEmptyState(
              icon: AppIcons.export,
              headline: Copy.destinationEmptyHeadline,
              message: Copy.destinationEmptyMessage,
            ),
          for (final Destination destination in loaded)
            AppListTile(
              key: ValueKey<String>('destination-${destination.id}'),
              title: destination.label,
              subtitle: _subtitle(destination),
              onTap: () => onRemove?.call(destination.id),
            ),
          if (editing &&
              labelController != null &&
              folderController != null &&
              secret != null) ...<Widget>[
            AppTextField(
              key: const ValueKey<String>('destination-label'),
              label: Copy.destinationLabel,
              controller: labelController!,
              dictation: false,
            ),
            AppTextField(
              key: const ValueKey<String>('destination-folder'),
              label: Copy.destinationFolder,
              controller: folderController!,
              dictation: false,
            ),
            AppTextField(
              key: const ValueKey<String>('destination-secret'),
              label: Copy.destinationSecret,
              controller: secret,
              obscureText: true,
              dictation: false,
            ),
            AppButton(
              key: const ValueKey<String>('destination-save'),
              label: Copy.destinationSave,
              onPressed: () => unawaited(_save(secret)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(TextEditingController secret) async {
    final bool ok = await onCheck?.call() ?? false;
    if (!ok) {
      return;
    }
    onSave?.call();
    secret.clear();
  }
}

String _subtitle(Destination destination) {
  final String? check = destination.lastCheck;
  final String base = '${_kindLabel(destination.kind)} · ${destination.folder}';
  if (check == null || check.isEmpty) {
    return base;
  }
  return '$base · $check';
}

String _kindLabel(DestinationKind kind) {
  return switch (kind) {
    DestinationKind.s3 => Copy.destinationKindS3,
    DestinationKind.googleDrive => Copy.destinationKindDrive,
    DestinationKind.oneDrive => Copy.destinationKindOneDrive,
    DestinationKind.dropbox => Copy.destinationKindDropbox,
    DestinationKind.webdav => Copy.destinationKindWebDav,
    DestinationKind.localFolder => Copy.destinationKindLocal,
  };
}

final StreamProvider<List<Destination>> _destinationListProvider =
    StreamProvider<List<Destination>>((Ref ref) {
      return ref.watch(destinationRepositoryProvider).watchAll();
    });
