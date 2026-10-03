import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/backend/relay_queue.dart';
import 'package:tapture/core/backend/relay_snapshot.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/merge/merge.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/offline_authority.dart';
import '../domain/role_gate.dart';
import 'account_session.dart';
import 'relay_controller.dart';

/// Optional encrypted change exchange for the open project, on the existing
/// package and merge flow (task 024 step 25).
///
/// What has been queued, sent and purged is always shown, even offline or
/// signed out. Relay stays off until a project manager turns it on; a
/// never-relay project offers no way to send; a role the server would refuse
/// is shown no control, and a lapsed sign-in says so in one line.
class RelayRoute extends ConsumerWidget {
  /// Opens the current project's relay controls.
  const RelayRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final BackendSession? session = ref.watch(backendSessionProvider);
    final BackendConfig? config = ref
        .watch(backendConfigProvider)
        .asData
        ?.value;
    final OfflineAuthority authority = ref.watch(offlineAuthorityProvider);
    final bool online =
        !ref.watch(offlineNowProvider) && session?.canUseBackend == true;
    final RelayActionState action = ref.watch(relayControllerProvider);
    // Registering a new project is the manager's, so the switch reads the
    // role rather than a project grant the registration has yet to give.
    final bool manages =
        authority.live &&
        config != null &&
        roleGateFor(config)?.allows(RoleCapability.manageProject) == true;
    return AppPage(
      title: localCopy.relayTitle,
      body: AsyncValueView<RelaySnapshot?>(
        value: ref.watch(relaySnapshotProvider),
        isEmpty: (RelaySnapshot? value) => value == null,
        empty: () => AppEmptyState(
          icon: AppIcons.project,
          headline: Copy.of(context).statusNoProject,
          message: Copy.of(context).relayChooseProject,
          actionLabel: Copy.of(context).recordsOpenProject,
          onAction: () => context.go(RoutePaths.projects),
        ),
        onRetry: () => ref.invalidate(relaySnapshotProvider),
        data: (RelaySnapshot? loaded) => _RelayBody(
          view: loaded!,
          authority: authority,
          manages: manages,
          online: online,
          action: action,
          reachable: config?.reachable ?? true,
        ),
      ),
    );
  }
}

class _RelayBody extends ConsumerWidget {
  const _RelayBody({
    required this.view,
    required this.authority,
    required this.manages,
    required this.online,
    required this.action,
    required this.reachable,
  });

  final RelaySnapshot view;
  final OfflineAuthority authority;
  final bool manages;
  final bool online;
  final RelayActionState action;
  final bool reachable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RelayController controller = ref.read(
      relayControllerProvider.notifier,
    );
    final bool relays = !view.neverRelay && authority.may(RoleCapability.relay);
    final Failure? failure = action.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ?_status(localCopy),
        if (failure != null)
          _Line(
            AppBanner(
              message: Copy.of(context).failureMessage(failure),
              icon: SnackTone.error.icon,
              tone: SnackTone.error,
            ),
          ),
        AppListTile(
          title: localCopy.relayQueued,
          subtitle: '${view.queued}',
          dense: true,
        ),
        AppListTile(
          title: localCopy.relaySent,
          subtitle: '${view.sent}',
          dense: true,
        ),
        AppListTile(
          title: localCopy.relayPurged,
          subtitle: '${view.purged}',
          dense: true,
        ),
        if (!view.neverRelay && manages)
          AppSwitchTile(
            title: localCopy.relayEnable,
            description: localCopy.relayEnableHelp,
            value: view.enabled,
            enabled: online && !action.busy,
            onChanged: (bool enabled) => unawaited(controller.enable(enabled)),
          ),
        if (!view.neverRelay && !manages && !view.enabled && authority.live)
          _Line(
            Text(
              localCopy.relayOff,
              style: AppText.body.copyWith(
                color: context.colors.onSurfaceMuted,
              ),
            ),
          ),
        if (relays) ...<Widget>[
          const SizedBox(height: Space.x3),
          if (!view.hasKey)
            AppButton(
              label: localCopy.relayAddKey,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => unawaited(_addKey(context)),
            ),
          if (view.enabled && view.hasKey) ...<Widget>[
            AppButton(
              label: localCopy.relayQueueProject,
              expand: true,
              busy: action.busy,
              onPressed: () => unawaited(controller.queueProject()),
            ),
            const SizedBox(height: Space.x2),
          ],
          AppButton(
            label: localCopy.relaySync,
            variant: AppButtonVariant.secondary,
            expand: true,
            busy: action.busy,
            onPressed: online
                ? () => unawaited(
                    controller.run(
                      (RelayQueue queue, String id) => queue.sync(id),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: Space.x2),
          for (final String id in view.incoming)
            AppListTile(
              title: localCopy.relayReceivedPackage,
              subtitle: id,
              trailing: const Icon(AppIcons.open),
              onTap: online && view.hasKey
                  ? () => unawaited(_preview(context, ref, id))
                  : null,
            ),
        ],
      ],
    );
  }

  /// One quiet line saying why server-bound controls are missing: never
  /// relay, no sign-in, a lapsed grant, or an unreachable server.
  Widget? _status(LocalizedCopy copy) {
    final (String, SnackTone)? line = switch (authority.state) {
      _ when view.neverRelay => (copy.relayNever, SnackTone.info),
      AuthorityState.neverSignedIn => (copy.relaySignInNeeded, SnackTone.info),
      AuthorityState.cachedExpired => (
        copy.backendGrantExpired,
        SnackTone.warning,
      ),
      _ when !online || !reachable => (copy.backendUnreachable, SnackTone.info),
      _ => null,
    };
    if (line == null) {
      return null;
    }
    final (String message, SnackTone tone) = line;
    return _Line(AppBanner(message: message, icon: tone.icon, tone: tone));
  }

  Future<void> _addKey(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return showAppSheet<void>(
      context,
      title: localCopy.relaySharedKey,
      contentSized: true,
      builder: (BuildContext _) => const _RelayKeyForm(),
    );
  }

  /// Decrypts a received package and hands it to the same merge preview and
  /// conflict path as a hand-carried bundle. It is acknowledged only after
  /// the merge is applied.
  Future<void> _preview(
    BuildContext context,
    WidgetRef ref,
    String packageId,
  ) async {
    final RelayQueue? queue = ref.read(relayQueueProvider);
    final String? projectId = ref.read(currentProjectProvider);
    if (queue == null || projectId == null) {
      return;
    }
    final Result<Uint8List> result = await queue.receive(projectId, packageId);
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case FailureResult<Uint8List>(:final Failure failure):
        showAppSnack(
          context,
          Copy.of(context).failureMessage(failure),
          tone: SnackTone.error,
        );
      case Success<Uint8List>(:final Uint8List value):
        await startPackageImport(
          context,
          ref,
          intoProjectId: projectId,
          supplied: PickedBytes(value, 'relay.tapture'),
          onApplied: () async {
            final Result<void> received = await queue.applied(
              projectId,
              packageId,
            );
            if (!context.mounted) {
              return;
            }
            ref.invalidate(relaySnapshotProvider);
            if (received case FailureResult<void>(:final Failure failure)) {
              showAppSnack(
                context,
                Copy.of(context).failureMessage(failure),
                tone: SnackTone.error,
              );
            }
          },
        );
    }
  }
}

/// A banner or line with the gap the list below it needs.
class _Line extends StatelessWidget {
  const _Line(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: child,
    );
  }
}

/// The shared project key, stored only in platform secure storage.
class _RelayKeyForm extends ConsumerStatefulWidget {
  const _RelayKeyForm();

  @override
  ConsumerState<_RelayKeyForm> createState() => _RelayKeyFormState();
}

class _RelayKeyFormState extends ConsumerState<_RelayKeyForm>
    with StateRefresh {
  final TextEditingController _key = TextEditingController();
  Failure? _error;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final RelayQueue? queue = ref.read(relayQueueProvider);
    final String? projectId = ref.read(currentProjectProvider);
    if (queue == null || projectId == null) {
      return false;
    }
    final Result<void> saved = await queue.saveKey(projectId, _key.text);
    if (!mounted) {
      return false;
    }
    if (saved case FailureResult<void>(:final Failure failure)) {
      refresh(() => _error = failure);
      return false;
    }
    ref.invalidate(relaySnapshotProvider);
    Navigator.of(context).pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? error = _error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: AppForm(
        compact: true,
        submitLabel: localCopy.save,
        errors: <String>[?error?.message],
        onSubmit: _save,
        fields: <Widget>[
          AppTextField(
            label: localCopy.relaySharedKey,
            controller: _key,
            obscureText: true,
            autofocus: true,
            requiredness: FieldRequiredness.required,
          ),
          Text(
            localCopy.relayKeyHelp,
            style: AppText.caption.copyWith(
              color: context.colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
