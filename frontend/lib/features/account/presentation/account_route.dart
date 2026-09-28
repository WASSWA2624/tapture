import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import 'account_session.dart';
import 'backend_settings_screen.dart';
import 'sign_in_controller.dart';
import 'sign_in_screen.dart';

/// Configures the organisation once and shows the cached account thereafter.
class AccountRoute extends ConsumerStatefulWidget {
  /// Opens settings, or the explicit sign-in route.
  const AccountRoute({super.key, this.signIn = false});

  /// Whether to display credentials after configuration is present.
  final bool signIn;

  @override
  ConsumerState<AccountRoute> createState() => _AccountRouteState();
}

class _AccountRouteState extends ConsumerState<AccountRoute> {
  final TextEditingController _server = TextEditingController();
  final TextEditingController _organisation = TextEditingController();

  @override
  void initState() {
    super.initState();
    final BackendConfig? config = ref.read(backendSessionProvider)?.config;
    _server.text = config?.baseUrl ?? '';
    _organisation.text = config?.organisationId ?? '';
  }

  @override
  void dispose() {
    _server.dispose();
    _organisation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BackendSession? session = ref.watch(backendSessionProvider);
    final BackendConfig config =
        ref.watch(backendConfigProvider).asData?.value ??
        session?.config ??
        const BackendConfig(baseUrl: '');
    final status = ref.watch(signInControllerProvider);
    if (config.baseUrl.isEmpty) {
      return AppPage(
        title: Copy.backendSettingsTitle,
        body: AppForm(
          errors: status.error == null
              ? const <String>[]
              : <String>[status.error!],
          fields: <Widget>[
            const Text(Copy.backendConfigurationHelp),
            AppTextField(
              label: Copy.backendServerAddress,
              controller: _server,
              requiredness: FieldRequiredness.required,
            ),
            AppTextField(
              label: Copy.signInOrganisation,
              controller: _organisation,
              requiredness: FieldRequiredness.optional,
            ),
          ],
          submitLabel: Copy.save,
          onSubmit: () =>
              ref.read(signInControllerProvider.notifier).submit(() async {
                if (session == null) throw const NetworkFailure();
                final Result<void> result = await session.configure(
                  _server.text,
                  _organisation.text,
                );
                if (result is FailureResult<void>) throw result.failure;
              }),
        ),
      );
    }
    if (widget.signIn && config.needsSignIn) {
      return SignInScreen(
        onSubmit: (String email, String password) async {
          if (session == null) throw const NetworkFailure();
          final Result<void> result = await session.signIn(email, password);
          if (result is FailureResult<void>) throw result.failure;
          if (context.mounted) context.go('/more/account');
        },
      );
    }
    return BackendSettingsScreen(
      config: config,
      actions: <Widget>[
        if (config.needsSignIn)
          AppButton(
            label: Copy.signInAction,
            onPressed: () => context.go('/more/sign-in'),
          ),
        if (!config.needsSignIn)
          AppButton(
            label: Copy.signOutAction,
            variant: AppButtonVariant.text,
            onPressed: session == null
                ? null
                : () async {
                    await session.signOut();
                  },
          ),
      ],
    );
  }
}
