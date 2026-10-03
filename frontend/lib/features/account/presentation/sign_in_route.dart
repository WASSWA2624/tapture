import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'account_session.dart';
import 'server_address_form.dart';
import 'sign_in_screen.dart';

/// The one sign-in, outside the shell like the lock screen (task 024 step
/// 23). A fresh configured install opens here once; an enrolled device never
/// does. Signing in, or choosing to continue without it, opens straight into
/// work.
class SignInRoute extends ConsumerWidget {
  /// Creates the route.
  const SignInRoute({super.key});

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
    return SignInScreen(
      onSubmit: (String email, String password) async {
        if (session == null) {
          throw const NetworkFailure();
        }
        final Result<void> result = await session.signIn(email, password);
        if (result case FailureResult<void>(:final Failure failure)) {
          throw failure;
        }
        if (!context.mounted) {
          return;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.projects);
        }
      },
      // Opened from Settings, back leaves; on first run work starts anyway.
      onLater: context.canPop() ? null : () => context.go(RoutePaths.projects),
    );
  }
}
