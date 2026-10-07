import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import 'account_session.dart';
import 'backend_settings_screen.dart';
import 'server_address_form.dart';

/// Explicit Server and account setup: the server address once for a self-hosted
/// install, then the cached account, sign-in and a confirmed sign-out.
class AccountRoute extends ConsumerWidget {
  /// Creates the route.
  const AccountRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BackendSession? session = ref.watch(backendSessionProvider);
    final BackendConfig config =
        ref.watch(backendConfigProvider).asData?.value ??
        session?.config ??
        const BackendConfig(baseUrl: '');
    if (config.baseUrl.isEmpty) {
      return const ServerAddressForm();
    }
    return BackendSettingsScreen(
      config: config,
      authority: session?.authority ?? AuthorityState.neverSignedIn,
      onSignIn: () => context.push(RoutePaths.signIn),
      onSignOut: session == null ? null : () => _signOut(context, session),
    );
  }

  /// Signs out after a confirmation that says signing back in needs the
  /// server. Local projects and attribution are untouched.
  Future<void> _signOut(BuildContext context, BackendSession session) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.signOutTitle,
      message: localCopy.signOutMessage,
      confirmLabel: localCopy.signOutAction,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    final Result<void> result = await session.signOut();
    if (result case FailureResult<void>(
      :final Failure failure,
    ) when context.mounted) {
      showAppSnack(
        context,
        Copy.of(context).failureMessage(failure),
        tone: SnackTone.error,
      );
    }
  }
}
