import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../cloud.dart'
    show
        DestinationRepositoryImpl,
        destinationRepositoryProvider,
        openCloudBackends;
import 'destination_remove_action.dart';

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
        data: (List<Destination> loaded) => _live(context, ref, loaded),
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

  Widget _live(BuildContext context, WidgetRef ref, List<Destination> loaded) {
    final _DestinationDraft draft = ref.watch(_draftProvider.notifier);
    ref.watch(_draftProvider);
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
              onTap: () => draft.beginEdit(destination),
              trailing: AppButton(
                key: ValueKey<String>('destination-remove-${destination.id}'),
                label: Copy.destinationRemove,
                onPressed: () =>
                    unawaited(_remove(context, ref, destination.id)),
              ),
            ),
          if (!draft.editing)
            AppButton(
              key: const ValueKey<String>('destination-add'),
              label: Copy.destinationAdd,
              onPressed: draft.beginAdd,
            ),
          if (draft.editing) ...<Widget>[
            AppTextField(
              key: const ValueKey<String>('destination-label'),
              label: Copy.destinationLabel,
              controller: draft.label,
              dictation: false,
              onChanged: (_) => draft.markDirty(),
            ),
            AppTextField(
              key: const ValueKey<String>('destination-folder'),
              label: Copy.destinationFolder,
              controller: draft.folder,
              dictation: false,
              onChanged: (_) => draft.markDirty(),
            ),
            AppTextField(
              key: const ValueKey<String>('destination-secret'),
              label: Copy.destinationSecret,
              controller: draft.secret,
              obscureText: true,
              dictation: false,
              onChanged: (_) => draft.markDirty(),
            ),
            AppButton(
              key: const ValueKey<String>('destination-test'),
              label: Copy.destinationTest,
              onPressed: () => unawaited(_probe(ref)),
            ),
            AppButton(
              key: const ValueKey<String>('destination-save'),
              label: Copy.destinationSave,
              onPressed: draft.checked ? () => unawaited(_commit(ref)) : null,
            ),
            if (draft.blocked != null)
              Text(
                draft.blocked!,
                key: const ValueKey<String>('destination-check-failed'),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _probe(WidgetRef ref) async {
    final _DestinationDraft draft = ref.read(_draftProvider.notifier);
    final DestinationRepositoryImpl repository = ref.read(
      destinationRepositoryProvider,
    );
    draft.credentialRef ??= repository.ids.newId();
    final String? credentialRef = draft.credentialRef;
    if (credentialRef == null) {
      return;
    }
    if (draft.secret.text.isNotEmpty) {
      await repository.secrets.put(credentialRef, draft.secret.text);
    }
    final Map<DestinationKind, CloudDestination> backends =
        await openCloudBackends(repository.secrets);
    final Result<CloudDestination> resolved = resolveDestination(
      draft.kind,
      backends,
    );
    if (resolved is FailureResult<CloudDestination>) {
      draft.fail(resolved.failure.message);
      return;
    }
    final Result<void> checked = await (resolved as Success<CloudDestination>)
        .value
        .check((
          id: draft.id ?? credentialRef,
          kind: draft.kind,
          label: draft.label.text,
          folder: draft.folder.text,
          credentialRef: credentialRef,
          lastCheck: null,
        ));
    if (checked is FailureResult<void>) {
      draft.fail(checked.failure.message);
      return;
    }
    draft.pass();
  }

  Future<void> _commit(WidgetRef ref) async {
    final _DestinationDraft draft = ref.read(_draftProvider.notifier);
    if (!draft.checked) {
      draft.fail(Copy.destinationCheckFailed);
      return;
    }
    final DestinationRepositoryImpl repository = ref.read(
      destinationRepositoryProvider,
    );
    final String credentialRef = draft.credentialRef ?? repository.ids.newId();
    final String id = draft.id ?? repository.ids.newId();
    final Result<void> saved = await repository.save((
      id: id,
      kind: draft.kind,
      label: draft.label.text,
      folder: draft.folder.text,
      credentialRef: credentialRef,
      lastCheck: Copy.destinationTest,
    ));
    if (saved is FailureResult<void>) {
      draft.fail(saved.failure.message);
      return;
    }
    draft.secret.clear();
    draft.finish();
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, String id) async {
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.destinationRemoveTitle,
      message: Copy.destinationRemoveMessage,
      confirmLabel: Copy.destinationRemove,
    );
    if (!confirmed) {
      return;
    }
    await DestinationRemoveAction.apply(
      repository: ref.read(destinationRepositoryProvider),
      id: id,
      confirmed: true,
    );
  }
}

/// Editor for adding or renaming a destination. The sign-in field starts empty.
final class _DestinationDraft extends Notifier<int> {
  /// Name shown in the list.
  final TextEditingController label = TextEditingController();

  /// Remote folder or bucket prefix.
  final TextEditingController folder = TextEditingController();

  /// Sign-in. Never filled from storage.
  final TextEditingController secret = TextEditingController();

  /// Existing row, when renaming.
  String? id;

  /// Credential handle. A new add gets a new one.
  String? credentialRef;

  /// Backend this draft will use.
  DestinationKind kind = DestinationKind.s3;

  /// Whether the form is open.
  bool editing = false;

  /// Whether the probe upload succeeded for the current fields.
  bool checked = false;

  /// Why the probe failed, when it did.
  String? blocked;

  @override
  int build() {
    ref.onDispose(label.dispose);
    ref.onDispose(folder.dispose);
    ref.onDispose(secret.dispose);
    return 0;
  }

  /// Opens a blank destination.
  void beginAdd() {
    id = null;
    credentialRef = null;
    kind = DestinationKind.s3;
    label.clear();
    folder.clear();
    secret.clear();
    checked = false;
    blocked = null;
    editing = true;
    state++;
  }

  /// Opens [destination] for a rename. The sign-in is not copied back.
  void beginEdit(Destination destination) {
    id = destination.id;
    credentialRef = destination.credentialRef;
    kind = destination.kind;
    label.text = destination.label;
    folder.text = destination.folder;
    secret.clear();
    checked = false;
    blocked = null;
    editing = true;
    state++;
  }

  /// A field changed, so the last probe no longer applies.
  void markDirty() {
    checked = false;
    blocked = null;
    state++;
  }

  /// Records a failed probe.
  void fail(String message) {
    checked = false;
    blocked = message;
    state++;
  }

  /// Records a successful probe.
  void pass() {
    checked = true;
    blocked = null;
    state++;
  }

  /// Closes the form after a save.
  void finish() {
    editing = false;
    checked = false;
    secret.clear();
    state++;
  }
}

final NotifierProvider<_DestinationDraft, int> _draftProvider =
    NotifierProvider<_DestinationDraft, int>(_DestinationDraft.new);

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
